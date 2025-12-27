import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Upload user profile photo
  Future<String> uploadUserPhoto(String userId, File imageFile) async {
    try {
      final fileName = '${userId}_${_uuid.v4()}.jpg';
      final ref = _storage
          .ref()
          .child(AppConstants.userPhotosPath)
          .child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Upload listing photos
  Future<List<String>> uploadListingPhotos(
    String listingId,
    List<File> imageFiles,
  ) async {
    try {
      final List<String> downloadUrls = [];

      for (var i = 0; i < imageFiles.length; i++) {
        final fileName = '${listingId}_${i}_${_uuid.v4()}.jpg';
        final ref = _storage
            .ref()
            .child(AppConstants.listingPhotosPath)
            .child(fileName);

        final uploadTask = await ref.putFile(imageFiles[i]);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload photos: $e');
    }
  }

  // Delete photo by URL
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail if photo doesn't exist
      debugPrint('Failed to delete photo: $e');
    }
  }

  // Delete multiple photos
  Future<void> deletePhotos(List<String> photoUrls) async {
    for (var url in photoUrls) {
      await deletePhoto(url);
    }
  }

  // Delete all listing photos
  Future<void> deleteListingPhotos(String listingId) async {
    try {
      final listRef = _storage
          .ref()
          .child(AppConstants.listingPhotosPath);

      final result = await listRef.listAll();

      for (var item in result.items) {
        if (item.name.startsWith(listingId)) {
          await item.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to delete listing photos: $e');
    }
  }
}
