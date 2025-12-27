import 'dart:io';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../config/constants.dart';

class ListingProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

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

      // 1. Create listing first to get an ID (or we can just use the one we'll generate)
      // Actually, FirestoreService.createListing generates an ID and returns it.
      final listingId = await _firestoreService.createListing(listing);

      // 2. Upload images using that ID
      if (imageFiles.isNotEmpty) {
        final imageUrls = await _storageService.uploadListingPhotos(listingId, imageFiles);
        
        // 3. Update listing with image URLs
        await _firestoreService.updateListing(listing.copyWith(id: listingId, images: imageUrls));
      }

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
  Future<bool> updateListing(ListingModel listing, {List<File>? newImageFiles}) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final imageUrls = await _storageService.uploadListingPhotos(listing.id, newImageFiles);
        listing = listing.copyWith(images: [...listing.images, ...imageUrls]);
      }

      await _firestoreService.updateListing(listing);
      
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

  // Delete listing with its images
  Future<bool> deleteListing(String listingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Delete images from storage
      await _storageService.deleteListingPhotos(listingId);

      // 2. Delete document from Firestore
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
