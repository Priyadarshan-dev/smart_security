import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Safely returns an ImageProvider for the given source (URL or base64).
  static ImageProvider? getImageProvider(dynamic source) {
    if (source == null) return null;

    final String value = source.toString();
    if (value.isEmpty) return null;

    try {
      // 1. Handle Network Images
      if (value.startsWith('http')) {
        return NetworkImage(value);
      }

      // 2. Handle Base64 Images
      String base64String = value;

      // Remove data URI prefix if present
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      // Remove whitespace
      base64String = base64String.replaceAll(RegExp(r'\s+'), '');

      // Add missing padding
      final int remainder = base64String.length % 4;
      if (remainder > 0) {
        base64String = base64String.padRight(
          base64String.length + (4 - remainder),
          '=',
        );
      }

      final Uint8List bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('Error getting image provider: $e');
      return null;
    }
  }

  /// Keep for backward compatibility with existing experiments if any
  static Uint8List? safeBase64Decode(String? source) {
    if (source == null || source.isEmpty) return null;

    try {
      String base64String = source;
      if (source.contains(',')) {
        base64String = source.split(',').last;
      }
      base64String = base64String.replaceAll(RegExp(r'\s+'), '');
      final int remainder = base64String.length % 4;
      if (remainder > 0) {
        base64String = base64String.padRight(
          base64String.length + (4 - remainder),
          '=',
        );
      }
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Error decoding base64: $e');
      return null;
    }
  }
}
