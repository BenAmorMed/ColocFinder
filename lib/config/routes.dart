import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/listings/listing_details_screen.dart';
import '../screens/listings/create_listing_screen.dart';
import '../screens/listings/my_listings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/listings/edit_listing_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/messaging/chats_screen.dart';
import '../screens/messaging/chat_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

class AppRoutes {
  // Route Names
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String listingDetails = '/listing-details';
  static const String createListing = '/create-listing';
  static const String myListings = '/my-listings';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String editListing = '/edit-listing';
  static const String favorites = '/favorites';
  static const String chats = '/chats';
  static const String chat = '/chat';
  static const String onboarding = '/onboarding';
  
  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case listingDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ListingDetailsScreen(
            listingId: args?['listingId'] ?? '',
          ),
        );
      
      case createListing:
        return MaterialPageRoute(builder: (_) => const CreateListingScreen());
      
      case myListings:
        return MaterialPageRoute(builder: (_) => const MyListingsScreen());
      
      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: args?['userId'],
          ),
        );
      
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      
      case editListing:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditListingScreen(
            listing: args?['listing'],
          ),
        );
      
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      
      case chats:
        return MaterialPageRoute(builder: (_) => const ChatsScreen());
      
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: args?['chatId'] ?? '',
            otherUserId: args?['otherUserId'] ?? '',
            otherUserName: args?['otherUserName'] ?? '',
          ),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
