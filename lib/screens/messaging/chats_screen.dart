import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../utils/helpers.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../utils/image_helper.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<ChatProvider, AuthProvider, NavigationProvider>(
        builder: (context, chatProvider, authProvider, navProvider, _) {
          if (!authProvider.isAuthenticated) {
            return EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Login Required',
              subtitle: 'Sign in to chat with listing owners and find your next roommate.',
              actionText: 'Go to Login',
              onActionPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, 
                AppRoutes.login, 
                (route) => false,
              ),
            );
          }

          if (chatProvider.chats.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle: 'Start exploring listings and message owners to begin a conversation.',
              actionText: 'Explore Listings',
              onActionPressed: () => navProvider.goToHome(),
            );
          }

          return ListView.builder(
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUserId = authProvider.user?.uid ?? '';
              final otherUserId = chat.participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        backgroundImage: chat.otherUserPhoto != null
                            ? (ImageHelper.isBase64(chat.otherUserPhoto!)
                                ? MemoryImage(ImageHelper.decodeBase64(chat.otherUserPhoto!))
                                : CachedNetworkImageProvider(chat.otherUserPhoto!)) as ImageProvider
                            : null,
                        child: chat.otherUserPhoto == null
                            ? Text(
                                Helpers.getInitials(chat.otherUserName ?? 'User'),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.otherUserName ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Helpers.getRelativeTime(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      chat.lastMessage.isEmpty ? 'Start a conversation' : chat.lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: {
                        'chatId': chat.id,
                        'otherUserId': otherUserId,
                        'otherUserName': chat.otherUserName ?? 'User',
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
