import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? phone;
  final String? bio;
  final String? gender;
  final String? school;
  final String? work;
  final List<String> favoriteListings;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.phone,
    this.bio,
    this.gender,
    this.school,
    this.work,
    List<String>? favoriteListings,
    DateTime? createdAt,
  })  : favoriteListings = favoriteListings ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phone': phone,
      'bio': bio,
      'gender': gender,
      'school': school,
      'work': work,
      'favoriteListings': favoriteListings,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      bio: map['bio'],
      gender: map['gender'],
      school: map['school'],
      work: map['work'],
      favoriteListings: List<String>.from(map['favoriteListings'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  // CopyWith method for updates
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? phone,
    String? bio,
    String? gender,
    String? school,
    String? work,
    List<String>? favoriteListings,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      school: school ?? this.school,
      work: work ?? this.work,
      favoriteListings: favoriteListings ?? this.favoriteListings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
