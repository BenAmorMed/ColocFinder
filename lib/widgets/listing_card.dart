import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/listing_model.dart';
import '../utils/image_helper.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';


class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ListingCard({
    super.key,
    required this.listing,
    this.onEdit,
    this.onDelete,
  });

  Future<void> _viewOnMap(BuildContext context) async {
    Uri url;
    if (listing.latitude != null && listing.longitude != null) {
      // Use coordinates for precise location
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${listing.latitude},${listing.longitude}');
    } else {
      // Fallback to location name search
      final query = Uri.encodeComponent(listing.location);
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }
    
    try {
      // Try to launch with external application (Google Maps / Apple Maps)
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to platform default (typically browser) if external app fails
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Could not open maps. Please check if you have a map app or browser installed.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.listingDetails,
          arguments: {'listingId': listing.id},
        );
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: listing.images.isNotEmpty
                      ? ImageHelper.getSafeImage(
                              url: listing.images.first,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.home_work, size: 50),
                              ),
                            )
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.home_work, size: 50),
                        ),
                ),
                
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favProvider, _) {
                      final isFavorite = favProvider.isFavorite(listing.id);
                      
                      return GestureDetector(
                        onTap: () {
                          favProvider.toggleFavorite(userId, listing.id, listing: listing);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Management Actions (Edit/Delete)
                if (onEdit != null || onDelete != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: Theme.of(context).iconTheme.color,
                            size: 20,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) onEdit!();
                          if (value == 'delete' && onDelete != null) onDelete!();
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorColor),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.location,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map_outlined, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _viewOnMap(context),
                        visualDensity: VisualDensity.compact,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.formattedPrice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
