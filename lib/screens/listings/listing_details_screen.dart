import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../utils/helpers.dart';

class ListingDetailsScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailsScreen({
    super.key,
    required this.listingId,
  });

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  ListingModel? _listing;
  UserModel? _owner;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final firestoreService = context.read<FirestoreService>();
    
    _listing = await firestoreService.getListing(widget.listingId);
    if (_listing != null) {
      _owner = await firestoreService.getUser(_listing!.userId);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    
    if (currentUserId == null) {
      Helpers.showSnackBar(context, 'Please login to message the owner', isError: true);
      return;
    }

    if (currentUserId == _listing?.userId) {
      Helpers.showSnackBar(context, "You can't message yourself!", isError: true);
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    final chatId = await chatProvider.createOrGetChat(currentUserId, _listing!.userId);

    if (!mounted) return;

    if (chatId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: {
          'chatId': chatId,
          'otherUserId': _owner!.id,
          'otherUserName': _owner!.name,
        },
      );
    } else {
      Helpers.showSnackBar(context, 'Failed to start chat', isError: true);
    }
  }

  void _shareListing() {
    Helpers.showSnackBar(
      context, 
      'Sharing link for "${_listing!.title}"', 
      isError: false,
    );
  }

  Future<void> _viewOnMap() async {
    final query = Uri.encodeComponent(_listing!.location);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        Helpers.showSnackBar(context, 'Could not open maps', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final isOwner = context.read<AuthProvider>().userModel?.id == _listing?.userId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(_listing!.description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Amenities'),
                  const SizedBox(height: 8),
                  _buildAmenities(),
                  const SizedBox(height: 24),
                  _buildOwnerSection(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isOwner ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? '';

    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: _listing!.images.isNotEmpty
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: _listing!.images.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: _listing!.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const LoadingIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(Icons.home_work_rounded, size: 100, color: AppTheme.primaryColor),
                    ),
            ),
            if (_listing!.images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _listing!.images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        Consumer<FavoritesProvider>(
          builder: (context, favProvider, _) {
            final isFavorite = favProvider.isFavorite(_listing!.id);
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: () {
                if (userId.isEmpty) {
                  Helpers.showSnackBar(context, 'Please login to favorite listings', isError: true);
                  return;
                }
                favProvider.toggleFavorite(userId, _listing!.id);
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: _shareListing,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _listing!.roomType,
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${_listing!.price.toInt()} TND/mo',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_listing!.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(_listing!.location, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton.icon(
              onPressed: _viewOnMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('View on Map'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAmenities() {
    final activeAmenities = _listing!.amenities.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    if (activeAmenities.isEmpty) {
      return const Text('No amenities listed');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activeAmenities.map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getAmenityIcon(amenity),
              const SizedBox(width: 8),
              Text(amenity),
            ],
          ),
        );
      }).toList(),
    );
  }

  Icon _getAmenityIcon(String amenity) {
    IconData iconData = Icons.done;
    if (amenity.contains('WiFi')) iconData = Icons.wifi;
    if (amenity.contains('Parking')) iconData = Icons.local_parking;
    if (amenity.contains('Kitchen')) iconData = Icons.kitchen;
    if (amenity.contains('Air')) iconData = Icons.ac_unit;
    if (amenity.contains('TV')) iconData = Icons.tv;
    
    return Icon(iconData, size: 18, color: AppTheme.primaryColor);
  }

  Widget _buildOwnerSection(BuildContext context) {
    if (_owner == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hosted by', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: _owner!.photoUrl != null ? NetworkImage(_owner!.photoUrl!) : null,
                child: _owner!.photoUrl == null ? Text(Helpers.getInitials(_owner!.name)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_owner!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Joined ${DateFormat.yMMMM().format(_owner!.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (_owner!.bio != null && _owner!.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_owner!.bio!, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Message Roommate',
                onPressed: _startChat,
                prefixIcon: Icons.chat_bubble_outline_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
