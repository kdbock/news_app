import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d2c31),
            ),
          ),
          if (onSeeAllPressed != null)
            TextButton(
              onPressed: onSeeAllPressed,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFd2982a),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'SEE ALL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}