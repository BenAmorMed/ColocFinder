
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageHelper {
  static bool isBase64(String str) {
    return str.startsWith('data:image') || str.length > 500 && !str.startsWith('http');
  }

  static Uint8List decodeBase64(String str) {
    var output = str;
    if (str.contains(',')) {
      output = str.split(',').last;
    }
    return base64Decode(output);
  }

  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static ImageProvider getSafeImageProvider(String? url) {
    if (url == null || url.isEmpty) {
      return const AssetImage('assets/images/placeholder.png'); // Fallback or transparent
    }

    if (isBase64(url)) {
      try {
        return MemoryImage(decodeBase64(url));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return const AssetImage('assets/images/placeholder.png');
      }
    }

    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    }
    
    // Fallback for file paths or assets if needed, but primarily for network/base64
    return NetworkImage(url); 
  }
  
  static Widget getSafeImage({
    required String? url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (url == null || url.isEmpty) {
      return placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (isBase64(url)) {
      try {
        return Image.memory(
          decodeBase64(url),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => errorWidget ?? const Icon(Icons.error),
        );
      } catch (e) {
        return errorWidget ?? const Icon(Icons.error);
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => errorWidget ?? const Icon(Icons.error),
    );
  }
}
