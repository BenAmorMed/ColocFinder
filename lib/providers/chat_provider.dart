import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../utils/image_helper.dart';
import 'dart:io';

class ChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ChatModel> _chats = [];
  final Map<String, List<MessageModel>> _chatMessages = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get messages for a specific chat
  List<MessageModel> getChatMessagesList(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  // Get stream of messages for a specific chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestoreService.getChatMessages(chatId);
  }

  // Load user's chats
  void loadChats(String userId) {
    _firestoreService.getUserChats(userId).listen(
      (chats) {
        _chats = chats;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Load messages for a chat
  void loadMessages(String chatId) {
    _firestoreService.getChatMessages(chatId).listen(
      (messages) {
        _chatMessages[chatId] = messages;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Create or get chat
  Future<String?> createOrGetChat(String currentUserId, String otherUserId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final chatId = await _firestoreService.createOrGetChat([currentUserId, otherUserId]);

      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Send message
  Future<bool> sendMessage(String chatId, MessageModel message, {String? otherUserId, String? currentUserName}) async {
    try {
      await _firestoreService.sendMessage(chatId, message);
      
      // Send notification if otherUserId is provided
      if (otherUserId != null) {
        final notification = NotificationModel(
          id: '',
          userId: otherUserId,
          title: currentUserName != null ? 'Message from $currentUserName' : 'New Message',
          body: message.type == MessageType.image ? 'Sent an image' : message.text,
          type: NotificationType.message,
          relatedId: chatId,
        );
        await _firestoreService.addNotification(notification);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send image message
  Future<bool> sendImageMessage(String chatId, MessageModel message, File imageFile, {String? otherUserId, String? currentUserName}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Convert image to Base64
      final imageUrl = await ImageHelper.fileToBase64(imageFile);
      
      // 2. Send message with Base64 data inside imageUrl
      await _firestoreService.sendMessage(chatId, message.copyWith(imageUrl: imageUrl));

      // Send notification if otherUserId is provided
      if (otherUserId != null) {
        final notification = NotificationModel(
          id: '',
          userId: otherUserId,
          title: currentUserName != null ? 'Message from $currentUserName' : 'New Message',
          body: 'Sent an image',
          type: NotificationType.message,
          relatedId: chatId,
        );
        await _firestoreService.addNotification(notification);
      }

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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
