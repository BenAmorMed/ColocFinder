import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message_model.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/common/loading_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;
    
    if (currentUserId == null) return;
    final currentUserName = authProvider.userModel?.name;

    final message = MessageModel(
      id: '',
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
    );

    Provider.of<ChatProvider>(context, listen: false).sendMessage(
      widget.chatId, 
      message,
      otherUserId: widget.otherUserId,
      currentUserName: currentUserName,
    );
    _messageController.clear();
    
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (image == null) return;
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;
    final currentUserName = authProvider.userModel?.name;
    
    if (currentUserId == null) return;

    final message = MessageModel(
      id: '',
      senderId: currentUserId,
      text: '', // Empty text for image-only message
      timestamp: DateTime.now(),
    );

    if (!mounted) return;
    await Provider.of<ChatProvider>(context, listen: false).sendImageMessage(
      widget.chatId, 
      message, 
      File(image.path),
      otherUserId: widget.otherUserId,
      currentUserName: currentUserName,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context.read<ChatProvider>().getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUserId = authProvider.user?.uid ?? '';

                if (messages.isEmpty) {
                  return const Center(child: Text('Start a conversation!'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  color: Colors.grey[600],
                  onPressed: chatProvider.isLoading ? null : _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    enabled: !chatProvider.isLoading,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                if (chatProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Theme.of(context).primaryColor,
                    onPressed: _handleSend,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
