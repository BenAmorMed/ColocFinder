class AppConstants {
  // App Info
  static const String appName = 'ColocFinder';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String bookingsCollection = 'bookings';
  static const String notificationsCollection = 'notifications';
  
  // Storage Paths
  static const String userPhotosPath = 'user_photos';
  static const String listingPhotosPath = 'listing_photos';
  
  // Limits
  static const int maxListingImages = 10;
  static const int maxImageSizeMB = 5;
  static const int messagesPageSize = 50;
  static const int listingsPageSize = 20;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxBioLength = 500;
  
  // Gender Options
  static const List<String> genderOptions = [
    'Not Specified',
    'Male',
    'Female',
  ];
  
  // Room Types
  static const List<String> roomTypes = [
    'Private Room',
    'Shared Room',
    'Studio',
    'Apartment',
  ];
  
  // Amenities
  static const List<String> availableAmenities = [
    'WiFi',
    'Parking',
    'Furnished',
    'Air Conditioning',
    'Heating',
    'Washer',
    'Kitchen',
    'TV',
    'Balcony',
    'Pet Friendly',
  ];
  
  // Price Range (in TND - Tunisian Dinar)
  static const double minPrice = 100;
  static const double maxPrice = 5000;
  
  // Date Format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Lifestyle Preferences
  static const Map<String, List<String>> lifestylePreferences = {
    'Smoking': ['Non-smoker', 'Smoker', 'Outside only'],
    'Pets': ['No pets', 'Pet lover', 'Has pets'],
    'Cleanliness': ['Very Clean', 'Moderate', 'Relaxed'],
    'Sleep Habits': ['Early Bird', 'Night Owl', 'Mixed'],
    'Social': ['Quiet/Private', 'Friendly/Social', 'Party Lover'],
  };

  // Sort Options
  static const List<SortOption> sortOptions = SortOption.values;
}

enum SortOption {
  newest,
  priceLowToHigh,
  priceHighToLow,
}

enum BookingStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}
