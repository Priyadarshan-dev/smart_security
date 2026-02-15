import 'dart:convert';
import 'package:flutter/material.dart';

class AddressProofWidget extends StatelessWidget {
  final String? image64;
  final VoidCallback onCapture;
  final VoidCallback? onRemove;

  const AddressProofWidget({
    super.key,
    this.image64,
    required this.onCapture,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Address Proof",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onCapture,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child:
                image64 != null
                    ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(image64!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (onRemove != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: onRemove,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to capture photo",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}
