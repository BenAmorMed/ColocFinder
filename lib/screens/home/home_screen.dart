import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../favorites/favorites_screen.dart';
import '../messaging/chats_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/common/empty_state.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      // Load listings
      Provider.of<ListingProvider>(context, listen: false).loadListings();
      
      // Load favorites
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites(userId);
      
      // Load chats
      Provider.of<ChatProvider>(context, listen: false).loadChats(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Widget> get _screens => [
        _buildHomeTab(),
        const FavoritesScreen(),
        const ChatsScreen(),
        const UserProfileScreen(),
      ];

  Widget _buildHomeTab() {
    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Your Perfect Colocation',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  Provider.of<ListingProvider>(context, listen: false)
                                      .setLocationFilter(null);
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        Provider.of<ListingProvider>(context, listen: false)
                            .setLocationFilter(value.isEmpty ? null : value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ListingProvider>(
                    builder: (context, provider, _) {
                      final count = provider.activeFilterCount;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () {
                              _showFilterBottomSheet();
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Listings Grid
        Expanded(
          child: Consumer<ListingProvider>(
            builder: (context, listingProvider, _) {
              if (listingProvider.isLoading) {
                return const LoadingIndicator();
              }

              if (listingProvider.listings.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No listings found',
                  subtitle: 'We couldn\'t find any listings matching your current filters. Try search for a different location or adjusting your price range.',
                  actionText: 'Clear All Filters',
                  onActionPressed: () => listingProvider.clearFilters(),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  listingProvider.loadListings();
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: listingProvider.listings.length,
                  itemBuilder: (context, index) {
                    return ListingCard(
                      listing: listingProvider.listings[index],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, _) {
        final currentIndex = navProvider.currentIndex;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('ColocFinder V2'),
            actions: [
              if (currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.createListing);
                  },
                ),
            ],
          ),
          body: _screens[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              navProvider.setIndex(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
