import 'dart:convert';
import 'dart:typed_data';

Uint8List? safeBase64Decode(String? value) {
  if (value == null || value.isEmpty) return null;

  try {
    // Remove possible data:image/...;base64, prefix
    final cleaned = value.contains(',')
        ? value.split(',').last
        : value;

    return base64Decode(cleaned);
  } catch (_) {
    return null;
  }
}

bool isValidUrl(String? value) {
  if (value == null || value.isEmpty) return false;
  final uri = Uri.tryParse(value);
  return uri != null && uri.hasAbsolutePath && uri.scheme.startsWith('http');
}
