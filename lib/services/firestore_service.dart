import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../config/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ USER OPERATIONS ============
  
  // Create user
  Future<void> createUser(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toMap());
  }

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    
    if (doc.exists) {
      return UserModel.fromSnapshot(doc);
    }
    return null;
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .update(user.toMap());
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .delete();
  }

  // ============ LISTING OPERATIONS ============
  
  // Create listing
  Future<String> createListing(ListingModel listing) async {
    final docRef = await _db
        .collection(AppConstants.listingsCollection)
        .add(listing.toMap());
    
    // Update the listing with its own ID
    await docRef.update({'id': docRef.id});
    
    return docRef.id;
  }

  // Generate a new listing ID
  String generateListingId() {
    return _db.collection(AppConstants.listingsCollection).doc().id;
  }

  // Create listing with a specific ID
  Future<void> createListingWithId(ListingModel listing) async {
    await _db
        .collection(AppConstants.listingsCollection)
        .doc(listing.id)
        .set(listing.toMap());
  }

  // Get listing by ID
  Future<ListingModel?> getListing(String listingId) async {
    final doc = await _db
        .collection(AppConstants.listingsCollection)
        .doc(listingId)
        .get();
    
    if (doc.exists) {
      return ListingModel.fromSnapshot(doc);
    }
    return null;
  }

  // Get all active listings
  Stream<List<ListingModel>> getListings({SortOption sortBy = SortOption.newest}) {
    Query query = _db
        .collection(AppConstants.listingsCollection)
        .where('isActive', isEqualTo: true);

    switch (sortBy) {
      case SortOption.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
      case SortOption.priceLowToHigh:
        query = query.orderBy('price', descending: false);
        break;
      case SortOption.priceHighToLow:
        query = query.orderBy('price', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ListingModel.fromSnapshot(doc))
        .toList());
  }

  // Search listings with filters
  Stream<List<ListingModel>> searchListings({
    String? location,
    double? minPrice,
    double? maxPrice,
    String? roomType,
    SortOption sortBy = SortOption.newest,
  }) {
    Query query = _db
        .collection(AppConstants.listingsCollection)
        .where('isActive', isEqualTo: true);

    if (roomType != null && roomType.isNotEmpty) {
      query = query.where('roomType', isEqualTo: roomType);
    }

    // Note: Firestore requires indexes for range filters on different fields.
    // To keep it simple and avoid composite index errors, we'll fetch and sort/filter the rest in-memory
    // if we encounter restriction issues, but for now we'll try basic price filters.
    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    // If we have price filters AND want to sort by price, it works.
    // If we want to sort by createdAt WITH price filters, it needs an index.
    // We'll use snapshots then sort in-memory for maximum flexibility.
    return query.snapshots().map((snapshot) {
      var listings = snapshot.docs
          .map((doc) => ListingModel.fromSnapshot(doc))
          .toList();

      // Filter by location in-memory
      if (location != null && location.isNotEmpty) {
        listings = listings
            .where((listing) =>
                listing.location.toLowerCase().contains(location.toLowerCase()))
            .toList();
      }

      // Sort in-memory
      switch (sortBy) {
        case SortOption.newest:
          listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case SortOption.priceLowToHigh:
          listings.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortOption.priceHighToLow:
          listings.sort((a, b) => b.price.compareTo(a.price));
          break;
      }

      return listings;
    });
  }

  // Get user's listings
  Stream<List<ListingModel>> getUserListings(String userId) {
    return _db
        .collection(AppConstants.listingsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListingModel.fromSnapshot(doc))
            .toList());
  }

  // Update listing
  Future<void> updateListing(ListingModel listing) async {
    await _db
        .collection(AppConstants.listingsCollection)
        .doc(listing.id)
        .update(listing.toMap());
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    await _db
        .collection(AppConstants.listingsCollection)
        .doc(listingId)
        .delete();
  }

  // ============ FAVORITES OPERATIONS ============
  
  // Add to favorites
  Future<void> addToFavorites(String userId, String listingId) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'favoriteListings': FieldValue.arrayUnion([listingId]),
    });
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String userId, String listingId) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'favoriteListings': FieldValue.arrayRemove([listingId]),
    });
  }

  // Get favorite listings
  Stream<List<ListingModel>> getFavoriteListings(String userId) async* {
    final userDoc = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    
    if (userDoc.exists) {
      final user = UserModel.fromSnapshot(userDoc);
      
      if (user.favoriteListings.isEmpty) {
        yield [];
        return;
      }

      yield* _db
          .collection(AppConstants.listingsCollection)
          .where(FieldPath.documentId, whereIn: user.favoriteListings)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ListingModel.fromSnapshot(doc))
              .toList());
    }
  }

  // ============ CHAT OPERATIONS ============
  
  // Create or get existing chat
  Future<String> createOrGetChat(List<String> participants) async {
    // Check if chat already exists
    final existingChats = await _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: participants[0])
        .get();

    for (var doc in existingChats.docs) {
      final chat = ChatModel.fromSnapshot(doc);
      if (chat.participants.contains(participants[1])) {
        return doc.id;
      }
    }

    // Create new chat
    final chat = ChatModel(
      id: '',
      participants: participants,
    );

    final docRef = await _db
        .collection(AppConstants.chatsCollection)
        .add(chat.toMap());

    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromSnapshot(doc))
            .toList());
  }

  // Send message
  Future<void> sendMessage(String chatId, MessageModel message) async {
    // Add message to subcollection
    await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .add(message.toMap());

    // Update chat's last message
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
    });
  }

  // Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(AppConstants.messagesPageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromSnapshot(doc))
            .toList());
  }
}
