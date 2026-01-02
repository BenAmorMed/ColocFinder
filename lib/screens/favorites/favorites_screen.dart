import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../config/routes.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<FavoritesProvider, AuthProvider, NavigationProvider>(
        builder: (context, favProvider, authProvider, navProvider, _) {
          if (!authProvider.isAuthenticated) {
            return EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Login Required',
              subtitle: 'Sign in to save and sync your favorite listings across all your devices.',
              actionText: 'Go to Login',
              onActionPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, 
                AppRoutes.login, 
                (route) => false,
              ),
            );
          }

          if (favProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (favProvider.favoriteListings.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline_rounded,
              title: 'No favorites yet',
              subtitle: 'Stay updated with the listings you love by adding them to your favorites.',
              actionText: 'Explore Listings',
              onActionPressed: () => navProvider.goToHome(),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favProvider.favoriteListings.length,
            itemBuilder: (context, index) {
              return ListingCard(
                listing: favProvider.favoriteListings[index],
              );
            },
          );
        },
      ),
    );
  }
}
