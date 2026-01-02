import 'package:flutter/material.dart';
import '../models/booking_model.dart';
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
      await _firestoreService.createBooking(booking);
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
  Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateBookingStatus(bookingId, status);
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
