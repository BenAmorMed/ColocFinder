import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
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
    final query = _db
        .collection(AppConstants.listingsCollection)
        .where('isActive', isEqualTo: true);

    return query.snapshots().map((snapshot) {
      final listings = snapshot.docs
          .map((doc) => ListingModel.fromSnapshot(doc))
          .toList();

      // Sort in-memory to avoid index requirement
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
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs
          .map((doc) => ListingModel.fromSnapshot(doc))
          .toList();
      
      // Sort in-memory to avoid index requirement
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
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
  Stream<List<ListingModel>> getFavoriteListings(String userId) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return [];
      
      final data = userDoc.data() as Map<String, dynamic>;
      final List<String> favoriteIds = List<String>.from(data['favoriteListings'] ?? []);
      
      if (favoriteIds.isEmpty) return [];

      // Note: Firestore whereIn is limited to 30 items
      final idsToFetch = favoriteIds.take(30).toList();
      
      final snapshot = await _db
          .collection(AppConstants.listingsCollection)
          .where(FieldPath.documentId, whereIn: idsToFetch)
          .get();

      return snapshot.docs
          .map((doc) => ListingModel.fromSnapshot(doc))
          .toList();
    });
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

  // Check if chat exists
  Future<bool> checkChatExists(String user1, String user2) async {
    final existingChats = await _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: user1)
        .get();

    for (var doc in existingChats.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(user2)) {
        return true;
      }
    }
    return false;
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = await Future.wait(snapshot.docs.map((doc) async {
        var chat = ChatModel.fromSnapshot(doc);
        
        final otherUserId = chat.participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          final userDoc = await _db.collection(AppConstants.usersCollection).doc(otherUserId).get();
          if (userDoc.exists) {
            final user = UserModel.fromSnapshot(userDoc);
            chat = chat.copyWith(
              otherUserName: user.name,
              otherUserPhoto: user.photoUrl,
            );
          }
        }
        return chat;
      }));
      
      // Sort in-memory to avoid index requirement
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
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

  // ============ BOOKING OPERATIONS ============

  // Create booking
  Future<String> createBooking(BookingModel booking) async {
    final docRef = _db.collection(AppConstants.bookingsCollection).doc();
    await _db.collection(AppConstants.bookingsCollection).doc(docRef.id).set(
      booking.toMap()..['id'] = docRef.id
    );
    return docRef.id;
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _db.collection(AppConstants.bookingsCollection).doc(bookingId).update({
      'status': status.index,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get bookings for guest (the one requesting)
  Stream<List<BookingModel>> getGuestBookings(String userId) {
    return _db
        .collection(AppConstants.bookingsCollection)
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromSnapshot(doc))
            .toList());
  }

  // Get bookings for host (the one who owns the listing)
  Stream<List<BookingModel>> getHostBookings(String userId) {
    return _db
        .collection(AppConstants.bookingsCollection)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromSnapshot(doc))
            .toList());
  }

  // ============ NOTIFICATION OPERATIONS ============

  // Get user notifications
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true) // Removed temporarily to fix potential index error
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromSnapshot(doc))
            .toList());
  }

  // Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsRead(String userId) async {
    final unread = await _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Generic method to add notification
  Future<void> addNotification(NotificationModel notification) async {
    final docRef = _db.collection(AppConstants.notificationsCollection).doc();
    await _db.collection(AppConstants.notificationsCollection).doc(docRef.id).set(
      notification.toMap()..['id'] = docRef.id
    );
  }
}
