import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Stream notifications
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _firestoreService.getNotifications(userId);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestoreService.markNotificationRead(notificationId);
    notifyListeners();
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await _firestoreService.markAllNotificationsRead(userId);
    notifyListeners();
  }
}
