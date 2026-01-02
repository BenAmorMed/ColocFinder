import 'dart:io';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/firestore_service.dart';
import '../utils/image_helper.dart';
import '../config/constants.dart';

class ListingProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ListingModel> _listings = [];
  List<ListingModel> _userListings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String? _searchLocation;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedRoomType;
  SortOption _selectedSort = SortOption.newest;

  List<ListingModel> get listings => _listings;
  List<ListingModel> get userListings => _userListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters for filters
  String? get searchLocation => _searchLocation;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get selectedRoomType => _selectedRoomType;
  SortOption get selectedSort => _selectedSort;

  int get activeFilterCount {
    int count = 0;
    if (_selectedRoomType != null) count++;
    if (_minPrice != null && _minPrice != AppConstants.minPrice) count++;
    if (_maxPrice != null && _maxPrice != AppConstants.maxPrice) count++;
    return count;
  }

  // Load all listings
  void loadListings() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getListings(sortBy: _selectedSort).listen(
      (listings) {
        _listings = listings;
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

  // Search listings with filters
  void searchListings() {
    _isLoading = true;
    notifyListeners();

    _firestoreService
        .searchListings(
          location: _searchLocation,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          roomType: _selectedRoomType,
          sortBy: _selectedSort,
        )
        .listen(
      (listings) {
        _listings = listings;
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

  // Load user's listings (updates local state)
  void loadUserListings(String userId) {
    _firestoreService.getUserListings(userId).listen(
      (listings) {
        _userListings = listings;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Get user's listings stream
  Stream<List<ListingModel>> getUserListings(String userId) {
    return _firestoreService.getUserListings(userId);
  }

  // Create listing with images
  Future<bool> createListingWithImages(ListingModel listing, List<File> imageFiles) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      debugPrint('📝 ListingProvider: Starting creation with Base64 workaround...');

      // Process images to Base64
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        for (var file in imageFiles) {
          final base64String = await ImageHelper.fileToBase64(file);
          imageUrls.add(base64String);
        }
        debugPrint('📝 ListingProvider: Processed ${imageUrls.length} photos to Base64.');
      }

      // Create the listing
      final finalListing = listing.copyWith(
        id: _firestoreService.generateListingId(),
        images: imageUrls,
      );
      
      await _firestoreService.createListingWithId(finalListing);

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

  // Update listing
  Future<bool> updateListing(
    ListingModel listing, {
    List<File>? newImageFiles,
    List<String>? removedImageUrls,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // In Base64 mode, we just update the images list
      List<String> updatedImages = List.from(listing.images);
      
      // Removed images are already handled by screen logic (passed in listing.images)
      // or we can filter them here if removedImageUrls is provided
      if (removedImageUrls != null) {
        updatedImages.removeWhere((url) => removedImageUrls.contains(url));
      }

      // Add new images as Base64
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        for (var file in newImageFiles) {
          final base64String = await ImageHelper.fileToBase64(file);
          updatedImages.add(base64String);
        }
      }

      final updatedListing = listing.copyWith(images: updatedImages);

      // Update Firestore
      await _firestoreService.updateListing(updatedListing);
      
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

  // Delete listing (no storage cleanup needed now)
  Future<bool> deleteListing(String listingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.deleteListing(listingId);

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

  // Update filters
  void setLocationFilter(String? location) {
    _searchLocation = location;
    searchListings();
  }

  void setPriceFilter(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    searchListings();
  }

  void setRoomTypeFilter(String? roomType) {
    _selectedRoomType = roomType;
    searchListings();
  }

  void setSortOption(SortOption sort) {
    _selectedSort = sort;
    searchListings();
  }

  void clearFilters() {
    _searchLocation = null;
    _minPrice = null;
    _maxPrice = null;
    _selectedRoomType = null;
    loadListings();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
