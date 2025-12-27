import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/firestore_service.dart';

class FavoritesProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ListingModel> _favoriteListings = [];
  List<String> _favoriteIds = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ListingModel> get favoriteListings => _favoriteListings;
  List<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if listing is favorite
  bool isFavorite(String listingId) {
    return _favoriteIds.contains(listingId);
  }

  // Load favorites
  void loadFavorites(String userId) {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getFavoriteListings(userId).listen(
      (listings) {
        _favoriteListings = listings;
        _favoriteIds = listings.map((l) => l.id).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String userId, String listingId) async {
    try {
      if (isFavorite(listingId)) {
        await _firestoreService.removeFromFavorites(userId, listingId);
        _favoriteIds.remove(listingId);
      } else {
        await _firestoreService.addToFavorites(userId, listingId);
        _favoriteIds.add(listingId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
