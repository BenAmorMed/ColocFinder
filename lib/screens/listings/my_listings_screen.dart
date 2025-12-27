import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/routes.dart';
import '../../widgets/common/empty_state.dart';
import '../../models/listing_model.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userId = authProvider.userModel?.id;
          
          if (userId == null) {
            return const Center(child: Text('Please login to view your listings'));
          }

          return Consumer<ListingProvider>(
            builder: (context, listingProvider, _) {
              return StreamBuilder<List<ListingModel>>(
                stream: listingProvider.getUserListings(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final listings = snapshot.data ?? [];

                  if (listings.isEmpty) {
                    return EmptyState(
                      icon: Icons.add_home_work_outlined,
                      title: 'No listings posted',
                      subtitle: 'Ready to find a roommate? Share your space with the community today.',
                      actionText: 'Post a Listing',
                      onActionPressed: () => Navigator.pushNamed(context, AppRoutes.createListing),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ListingCard(
                          listing: listing,
                          onEdit: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.editListing,
                              arguments: {'listing': listing},
                            );
                          },
                          onDelete: () => _showDeleteDialog(context, listing.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createListing),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String listingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<ListingProvider>(context, listen: false).deleteListing(listingId);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete listing'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
