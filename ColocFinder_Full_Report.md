# ColocFinder - Full Project Report

## 1. Executive Summary
ColocFinder is a modern Flutter-based mobile application designed to simplify the process of finding roommates and shared housing. By leveraging Firebase for real-time data and authentication, and integrating advanced matching algorithms, it provides a seamless experience for users looking for compatible living arrangements.

## 2. Project Overview
The application caters to two primary user roles:
- **Seekers**: Individuals looking for a room or a roommate.
- **Owners/Listers**: Individuals offering a room or looking for a roommate for their existing listing.

ColocFinder goes beyond simple listings by incorporating lifestyle preferences to calculate compatibility scores between users.

---

## 3. Technical Stack
- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform UI)
- **Language**: [Dart](https://dart.dev/)
- **Backend as a Service (BaaS)**: [Firebase](https://firebase.google.com/)
    - **Authentication**: Firebase Auth (Email/Password)
    - **Database**: Cloud Firestore (NoSQL)
    - **Storage**: Firebase Storage (for profile and listing images)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Maps & Location**: 
    - [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap integration)
    - [geolocator](https://pub.dev/packages/geolocator)
    - [geocoding](https://pub.dev/packages/geocoding)
- **Utilities**:
    - [intl](https://pub.dev/packages/intl) (Formatting)
    - [uuid](https://pub.dev/packages/uuid) (Unique IDs)
    - [cached_network_image](https://pub.dev/packages/cached_network_image) (Optimized image loading)

---

## 4. Application Architecture
The project follows a modular architecture organized by functionality:

### Folder Hierarchy
- `lib/config`: Global constants, routes, and theme definitions.
- `lib/models`: Data models representing core entities (User, Listing, Booking, Chat).
- `lib/providers`: State management classes using the Provider pattern.
- `lib/screens`: UI screens grouped by feature (Auth, Listings, Messaging, etc.).
- `lib/services`: Singleton services for Firebase interaction and business logic.
- `lib/utils`: Helper functions and utility classes.
- `lib/widgets`: Reusable UI components.

### State Management
ColocFinder uses the **Provider** pattern for reactive state management. Dedicated providers handle:
- **AuthProvider**: Manages user session and authentication state.
- **ListingProvider**: Handles property listing data and CRUD operations.
- **ChatProvider**: Manages real-time messaging and chat history.
- **BookingProvider**: Tracks visit requests and booking statuses.

---

## 5. Key Features & Functionalities

### 👤 User Profiles & Preferences
Users can create detailed profiles including lifestyle preferences (e.g., smoking, pets, cleanliness). These preferences are stored as map structures in Firestore.

### 🏠 Listing Management
- **Search & Filter**: Users can browse listings with advanced filters.
- **Map View**: Integrated OpenStreetMap for location-based searching.
- **CRUD Operations**: Users can create, edit, and delete their own listings.

### 🤝 Advanced Matching System
The `MatchingService` calculates a compatibility score (0-100%) between users based on their shared lifestyle preferences. This helps users find the most compatible roommates.

### 💬 Real-time Messaging
A fully functional chat system allows seekers and listers to communicate directly within the app, powered by Firestore's real-time listeners.

### 📅 Booking & Visit Management
Users can request visits for specific listings. Listers can approve or decline these requests, with real-time status updates.

### ❤️ Favorites & Notifications
- **Favorites**: Save listings for quick access.
- **Notifications**: Real-time alerts for new messages and booking updates.

---

## 6. Technical Implementation Details

### Database Schema (Firestore)
- **users**: User profiles, preferences, and metadata.
- **listings**: Property details, pricing, location, and images.
- **chats**: Chat room metadata.
- **messages**: Individual messages nested within chats (sub-collection).
- **bookings**: Visit requests linked to users and listings.

### UI/UX Highlights
- Responsive design using Flutter's layout system.
- Custom theme with dark/light mode support.
- Smooth transitions and loading states using `flutter_spinkit`.

---

## 7. Conclusion
ColocFinder provides a robust and scalable solution for the "roommate finding" problem. Its modular architecture and choice of modern technologies ensure high performance and easy maintainability for future feature expansions.
