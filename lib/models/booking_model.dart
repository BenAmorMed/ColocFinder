import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class BookingModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String requesterId;
  final String requesterName;
  final String? requesterPhoto;
  final String ownerId;
  final String ownerName;
  final BookingStatus status;
  final DateTime moveInDate;
  final int durationMonths;
  final double totalPrice;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhoto,
    required this.ownerId,
    required this.ownerName,
    this.status = BookingStatus.pending,
    required this.moveInDate,
    required this.durationMonths,
    required this.totalPrice,
    this.message,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhoto': requesterPhoto,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'status': status.index,
      'moveInDate': Timestamp.fromDate(moveInDate),
      'durationMonths': durationMonths,
      'totalPrice': totalPrice,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      listingId: map['listingId'] ?? '',
      listingTitle: map['listingTitle'] ?? '',
      listingImage: map['listingImage'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterPhoto: map['requesterPhoto'],
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      status: BookingStatus.values[map['status'] ?? 0],
      moveInDate: (map['moveInDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMonths: map['durationMonths'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      message: map['message'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory BookingModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return BookingModel.fromMap(data);
  }

  BookingModel copyWith({
    BookingStatus? status,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id,
      listingId: listingId,
      listingTitle: listingTitle,
      listingImage: listingImage,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterPhoto: requesterPhoto,
      ownerId: ownerId,
      ownerName: ownerName,
      status: status ?? this.status,
      moveInDate: moveInDate,
      durationMonths: durationMonths,
      totalPrice: totalPrice,
      message: message,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
