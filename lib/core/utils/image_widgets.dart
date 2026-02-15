import 'package:ceedeeyes/core/utils/base64.dart';
import 'package:flutter/material.dart';

Widget buildVisitorAvatar(String? imageUrl) {
  final imageBytes = safeBase64Decode(imageUrl);

  if (imageBytes != null) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: MemoryImage(imageBytes),
    );
  }

  if (isValidUrl(imageUrl)) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: NetworkImage(imageUrl!),
    );
  }

  return CircleAvatar(
    radius: 30,
    backgroundColor: Colors.grey.shade200,
    child: const Icon(Icons.person, size: 30),
  );
}
