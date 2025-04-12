import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LazyAdImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const LazyAdImage({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        ),
      ),
    );
  }
}