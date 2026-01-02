import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ImageHelper {
  /// Converts a File to a Base64 string with image prefix
  static Future<String> fileToBase64(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final String base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// Helper to determine if a string is a Base64 image
  static bool isBase64(String path) {
    return path.startsWith('data:image');
  }

  /// Decodes base64 string to bytes
  static Uint8List decodeBase64(String base64String) {
    final String cleanString = base64String.contains('base64,') 
        ? base64String.split('base64,').last 
        : base64String;
    return base64Decode(cleanString);
  }
}
