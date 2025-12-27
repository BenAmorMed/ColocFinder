import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class ChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

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
  Future<bool> sendMessage(String chatId, MessageModel message) async {
    try {
      await _firestoreService.sendMessage(chatId, message);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send image message
  Future<bool> sendImageMessage(String chatId, MessageModel message, File imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Upload image
      final imageUrl = await _storageService.uploadUserPhoto(message.senderId, imageFile);
      
      // 2. Send message with imageUrl
      await _firestoreService.sendMessage(chatId, message.copyWith(imageUrl: imageUrl));

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
