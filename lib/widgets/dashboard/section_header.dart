import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllPressed;
  final String? seeAllText;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAllPressed,
    this.seeAllText = 'See All',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and button above the line
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d2c31),
                ),
              ),
              const Spacer(),
              if (onSeeAllPressed != null)
                TextButton(
                  onPressed: onSeeAllPressed,
                  child: Text(
                    seeAllText!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFd2982a),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Gold line below the title and button
        Container(
          height: 2.0,
          color: const Color(0xFFd2982a),
          margin: const EdgeInsets.only(bottom: 8.0),
        ),
      ],
    );
  }
}
