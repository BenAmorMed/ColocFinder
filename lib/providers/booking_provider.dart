import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../config/constants.dart';

class BookingProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Create booking request
  Future<bool> createBooking(BookingModel booking) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookingId = await _firestoreService.createBooking(booking);
      
      // Create notification for the host
      final notification = NotificationModel(
        id: '', // Will be set by firestore
        userId: booking.ownerId,
        title: 'New Booking Request',
        body: '${booking.requesterName} wants to book ${booking.listingTitle}',
        type: NotificationType.bookingRequest,
        relatedId: bookingId,
      
      // I will fix FirestoreService.createBooking to return ID or similar, but for now let's just add notification. 
      // Actually, safest is to use the same logic as FirestoreService or just rely on generic notification without specific ID if difficult.
      // But relatedId is important.
      // Let's rely on the fact I can generate ID here if I want.
      // Or I can update FirestoreService first.
      // Let's just create notification.
      
      await _firestoreService.addNotification(notification);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(BookingModel booking, BookingStatus status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateBookingStatus(booking.id, status);
      
      // Notify the requester
      String title = 'Booking Update';
      String body = 'Your booking for ${booking.listingTitle} has been updated.';
      
      if (status == BookingStatus.accepted) {
        title = 'Booking Accepted!';
        body = 'Great news! ${booking.ownerName} accepted your booking request for ${booking.listingTitle}.';
      } else if (status == BookingStatus.rejected) {
        title = 'Booking Declined';
        body = 'Your booking request for ${booking.listingTitle} was declined.';
      }

      final notification = NotificationModel(
        id: '',
        userId: booking.requesterId,
        title: title,
        body: body,
        type: NotificationType.bookingUpdate,
        relatedId: booking.id,
      );
      
      await _firestoreService.addNotification(notification);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Stream my requests (as a guest)
  Stream<List<BookingModel>> streamMyRequests(String userId) {
    return _firestoreService.getGuestBookings(userId);
  }

  // Stream received requests (as a host)
  Stream<List<BookingModel>> streamReceivedRequests(String userId) {
    return _firestoreService.getHostBookings(userId);
  }
}
