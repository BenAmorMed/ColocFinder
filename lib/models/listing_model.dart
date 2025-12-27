import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final double price;
  final String roomType;
  final List<String> images;
  final Map<String, bool> amenities;
  final DateTime availableFrom;
  final DateTime createdAt;
  final bool isActive;
  final String? userName;
  final String? userPhoto;

  ListingModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.roomType,
    List<String>? images,
    Map<String, bool>? amenities,
    DateTime? availableFrom,
    DateTime? createdAt,
    this.isActive = true,
    this.userName,
    this.userPhoto,
  })  : images = images ?? [],
        amenities = amenities ?? {},
        availableFrom = availableFrom ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'roomType': roomType,
      'images': images,
      'amenities': amenities,
      'availableFrom': Timestamp.fromDate(availableFrom),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'userName': userName,
      'userPhoto': userPhoto,
    };
  }

  // Create from Firestore document
  factory ListingModel.fromMap(Map<String, dynamic> map) {
    return ListingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      roomType: map['roomType'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      amenities: Map<String, bool>.from(map['amenities'] ?? {}),
      availableFrom: (map['availableFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      userName: map['userName'],
      userPhoto: map['userPhoto'],
    );
  }

  // Create from Firestore DocumentSnapshot
  factory ListingModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ListingModel.fromMap(data);
  }

  // CopyWith method for updates
  ListingModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? location,
    double? price,
    String? roomType,
    List<String>? images,
    Map<String, bool>? amenities,
    DateTime? availableFrom,
    DateTime? createdAt,
    bool? isActive,
    String? userName,
    String? userPhoto,
  }) {
    return ListingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      price: price ?? this.price,
      roomType: roomType ?? this.roomType,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      availableFrom: availableFrom ?? this.availableFrom,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
    );
  }

  // Helper method to get formatted price
  String get formattedPrice => '${price.toStringAsFixed(0)} TND';
}
