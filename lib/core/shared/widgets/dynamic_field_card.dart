import 'package:flutter/material.dart';

class DynamicFieldCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Widget child;
  final Color? color;

  const DynamicFieldCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
  
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (color ?? Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: color ?? Colors.blue, size: 20),
                    child: icon,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
