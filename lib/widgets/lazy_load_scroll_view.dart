import 'package:flutter/material.dart';

class LazyLoadScrollView extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onEndOfPage;
  final double endOfPageThreshold;
  final bool onEndOfPageCalled;
  final ScrollController? controller;

  const LazyLoadScrollView({
    super.key,
    required this.child,
    required this.onEndOfPage,
    this.endOfPageThreshold = 200.0,
    this.onEndOfPageCalled = false,
    this.controller,
  });

  @override
  State<LazyLoadScrollView> createState() => _LazyLoadScrollViewState();
}

class _LazyLoadScrollViewState extends State<LazyLoadScrollView> {
  late ScrollController _controller;
  bool _isLoading = false;
  bool _onEndOfPageCalled = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _controller.addListener(_scrollListener);
    _onEndOfPageCalled = widget.onEndOfPageCalled;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_scrollListener);
    }
    super.dispose();
  }

  Future<void> _scrollListener() async {
    if (_isLoading) return;

    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.position.pixels;
    final delta = widget.endOfPageThreshold;

    if (maxScroll - currentScroll <= delta && !_onEndOfPageCalled) {
      setState(() => _isLoading = true);
      
      // Call onEndOfPage and wait for it to complete
      await widget.onEndOfPage();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _onEndOfPageCalled = true;
        });
        
        // Reset the flag after a delay to allow multiple loads
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _onEndOfPageCalled = false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child is ScrollView) {
      final ScrollView scrollView = widget.child as ScrollView;
      
      // Apply the controller to the child ScrollView
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          overscroll: false,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return CustomScrollView(
              controller: _controller,
              slivers: [
                SliverToBoxAdapter(child: scrollView),
                if (_isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }
    
    // If child is not a ScrollView, wrap it in a SingleChildScrollView
    return SingleChildScrollView(
      controller: _controller,
      child: Column(
        children: [
          widget.child,
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}