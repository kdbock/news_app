import 'package:flutter/material.dart';

class PremiumAdCard extends StatelessWidget {
  final String headline;
  final String description;
  final String imageUrl;
  final VoidCallback onTap;

  const PremiumAdCard({
    super.key,
    required this.headline,
    required this.description,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // Headline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                headline,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
