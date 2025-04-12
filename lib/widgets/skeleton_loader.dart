import 'package:flutter/material.dart';

class SkeletonLoaders {
  // Generic skeleton box with shimmer effect
  static Widget container({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return _ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // News article card skeleton
  static Widget newsCard() {
    return _ShimmerEffect(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Image placeholder
            Container(
              height: 200,
              color: Colors.grey[300],
            ),
            
            // Title and info placeholders
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title lines
                  Container(
                    height: 20,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.grey[300],
                    width: double.infinity,
                  ),
                  Container(
                    height: 20,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.grey[300],
                    width: double.infinity * 0.7,
                  ),
                  
                  // Date and author
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 14,
                        width: 100,
                        color: Colors.grey[300],
                      ),
                      Container(
                        height: 14,
                        width: 80,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action buttons placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 16,
                    width: 60,
                    color: Colors.grey[300],
                  ),
                  Container(
                    height: 16,
                    width: 80,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // News section skeleton with multiple items
  static Widget newsSection() {
    return _ShimmerEffect(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Shimmer effect widget
class _ShimmerEffect extends StatefulWidget {
  final Widget child;

  const _ShimmerEffect({required this.child});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation, 
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.1, 0.3, 0.4],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}