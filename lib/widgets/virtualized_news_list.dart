import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/widgets/skeleton_loader.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VirtualizedNewsList extends StatefulWidget {
  final List<Article> initialArticles;
  final Future<List<Article>> Function({int skip, int take, bool forceRefresh}) fetcher;
  final int pageSize;
  final bool showLoadingIndicator;
  final Function(Article) onArticleTapped;
  final String categoryKey;
  
  const VirtualizedNewsList({
    super.key,
    required this.initialArticles,
    required this.fetcher,
    required this.onArticleTapped,
    required this.categoryKey,
    this.pageSize = 10,
    this.showLoadingIndicator = true,
  });

  @override
  State<VirtualizedNewsList> createState() => _VirtualizedNewsListState();
}

class _VirtualizedNewsListState extends State<VirtualizedNewsList> {
  final List<Article> _articles = [];
  final Map<String, bool> _visibleItems = {};
  bool _loading = false;
  bool _hasMore = true;
  bool _initialLoad = true;
  int _currentPage = 0;
  
  // For managing visible items
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeArticles();
    _scrollController.addListener(_onScroll);
  }

  void _initializeArticles() {
    setState(() {
      _articles.clear();
      _articles.addAll(widget.initialArticles);
      _initialLoad = false;
      _hasMore = widget.initialArticles.length >= widget.pageSize;
    });
  }

  @override
  void didUpdateWidget(VirtualizedNewsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialArticles != oldWidget.initialArticles) {
      _initializeArticles();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Check if we need to load more items
  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = MediaQuery.of(context).size.height * 0.25; // 25% of screen height
    
    if (maxScroll - currentScroll <= delta && !_loading && _hasMore) {
      _loadMore();
    }
  }

  // Load next page of articles
  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    
    setState(() => _loading = true);
    
    try {
      final nextPage = _currentPage + 1;
      final skip = nextPage * widget.pageSize;
      
      final newArticles = await widget.fetcher(
        skip: skip, 
        take: widget.pageSize,
        forceRefresh: false,
      );
      
      if (mounted) {
        setState(() {
          _articles.addAll(newArticles);
          _loading = false;
          _currentPage = nextPage;
          _hasMore = newArticles.length >= widget.pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more articles: $e')),
        );
      }
    }
  }

  // Track visibility of items for optimizing rendering
  void _updateItemVisibility(String id, bool isVisible) {
    _visibleItems[id] = isVisible;
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoad && widget.showLoadingIndicator) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => SkeletonLoaders.newsCard(),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _articles.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFd2982a)),
            ),
          );
        }
        
        final article = _articles[index];
        
        return VisibilityDetector(
          key: Key('article-${article.id}'),
          onVisibilityChanged: (info) {
            final isVisible = info.visibleFraction > 0.1;
            _updateItemVisibility(article.id, isVisible);
          },
          child: NewsCard(
            article: article,
            onReadMore: () => widget.onArticleTapped(article),
            sourceTag: article.primaryCategory ?? widget.categoryKey,
          ),
        );
      },
    );
  }
}