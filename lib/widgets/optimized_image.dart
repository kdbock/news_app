import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neusenews/services/image_optimization_service.dart';

class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final bool useHero;
  final String? heroTag;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.placeholder,
    this.borderRadius,
    this.useHero = false,
    this.heroTag,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  final ImageOptimizationService _imageService = ImageOptimizationService();
  String? _optimizedUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _optimizeImage();
  }
  
  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _optimizeImage();
    }
  }
  
  Future<void> _optimizeImage() async {
    setState(() {
      _isLoading = true;
    });
    
    if (widget.imageUrl.isEmpty) {
      setState(() {
        _optimizedUrl = widget.imageUrl;
        _isLoading = false;
      });
      return;
    }
    
    try {
      // Calculate target width based on actual device width if not specified
      int targetWidth = 720; // Default
      if (widget.width != null) {
        targetWidth = widget.width!.toInt();
      } else {
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        final deviceWidth = MediaQuery.of(context).size.width;
        targetWidth = (deviceWidth * devicePixelRatio).toInt();
      }
      
      final optimizedUrl = await _imageService.getOptimizedImageUrl(
        widget.imageUrl,
        maxWidth: targetWidth,
      );
      
      if (mounted) {
        setState(() {
          _optimizedUrl = optimizedUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimizedUrl = widget.imageUrl; // Fallback to original URL
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _optimizedUrl == null) {
      return _buildPlaceholder();
    }
    
    Widget imageWidget = CachedNetworkImage(
      imageUrl: _optimizedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: widget.errorWidget ?? (context, url, error) => _buildErrorWidget(),
    );
    
    // Apply border radius if specified
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }
    
    // Apply hero animation if specified
    if (widget.useHero && widget.heroTag != null) {
      return Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFd2982a),
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[400],
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}