import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/widgets/webview_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:neusenews/widgets/bottom_nav_bar.dart';
import 'package:neusenews/features/advertising/widgets/ad_banner.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final NewsService _newsService = NewsService();
  final AnalyticsService _analyticsService = AnalyticsService();
  List<Article> _relatedArticles = [];
  bool _isLoadingRelated = false;
  bool _isSaved = false;
  late Article _article;
  final ScrollController _scrollController = ScrollController();
  bool _showToTopButton = false;
  double _scrollProgress = 0.0;
  final int _selectedIndex = 1; // Default to News tab (index 1)

  @override
  void initState() {
    super.initState();

    // Setup scroll controller for scroll-to-top button
    _scrollController.addListener(_scrollListener);

    // We'll load related articles and check saved status after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _article = ModalRoute.of(context)!.settings.arguments as Article;

      // Mark article as read
      _markAsRead(_article.id);

      // Track article view
      _trackArticleView();

      // Load related articles
      _loadRelatedArticles();

      // Check if article is saved
      _checkIfSaved();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Show/hide scroll-to-top button
    if (_scrollController.offset >= 200 && !_showToTopButton) {
      setState(() {
        _showToTopButton = true;
      });
    } else if (_scrollController.offset < 200 && _showToTopButton) {
      setState(() {
        _showToTopButton = false;
      });
    }

    // Calculate scroll progress
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _scrollProgress =
            _scrollController.offset /
            _scrollController.position.maxScrollExtent;
      });
    }
  }

  Future<void> _loadRelatedArticles() async {
    setState(() {
      _isLoadingRelated = true;
    });

    try {
      // Get articles from the same category if possible
      final categoryMatch =
          _article.categories.isNotEmpty ? _article.categories.first : null;

      List<Article> articles;
      if (categoryMatch != null && categoryMatch.toLowerCase() == 'sports') {
        articles = await _newsService.fetchSports(take: 5);
      } else if (categoryMatch != null &&
          (categoryMatch.toLowerCase() == 'politics' ||
              categoryMatch.toLowerCase() == 'political news')) {
        articles = await _newsService.fetchPolitics(take: 5);
      } else {
        // For now, just fetch more local news as "related"
        articles = await _newsService.fetchLocalNews(take: 5);
      }

      // Filter out the current article and limit to 3
      final related =
          articles.where((a) => a.id != _article.id).take(3).toList();

      if (mounted) {
        setState(() {
          _relatedArticles = related;
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
        debugPrint('Error loading related articles: $e');
      }
    }
  }

  Future<void> _markAsRead(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readArticlesJson = prefs.getString('read_articles') ?? '{}';
      final readArticles = Map<String, dynamic>.from(
        jsonDecode(readArticlesJson),
      );

      // Store article id with timestamp
      readArticles[articleId] = DateTime.now().millisecondsSinceEpoch;

      // Clean up old entries (older than 30 days)
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
      readArticles.removeWhere(
        (_, timestamp) => now - timestamp > thirtyDaysMs,
      );

      // Save back to preferences
      await prefs.setString('read_articles', jsonEncode(readArticles));
    } catch (e) {
      debugPrint('Error marking article as read: $e');
    }
  }

  Future<void> _trackArticleView() async {
    try {
      // Track view in analytics
      await _analyticsService.incrementArticleView(_article.id);
    } catch (e) {
      debugPrint('Error tracking article view: $e');
    }
  }

  Future<void> _checkIfSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedArticlesJson = prefs.getString('saved_articles') ?? '[]';
      final List<dynamic> savedArticles = jsonDecode(savedArticlesJson);

      setState(() {
        _isSaved = savedArticles.contains(_article.id);
      });
    } catch (e) {
      debugPrint('Error checking if article is saved: $e');
    }
  }

  Future<void> _toggleSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedArticlesJson = prefs.getString('saved_articles') ?? '[]';
      final List<dynamic> savedArticles = jsonDecode(savedArticlesJson);

      if (_isSaved) {
        savedArticles.remove(_article.id);
      } else {
        savedArticles.add(_article.id);
      }

      await prefs.setString('saved_articles', jsonEncode(savedArticles));

      setState(() {
        _isSaved = !_isSaved;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved
                  ? 'Article saved for offline reading'
                  : 'Article removed from saved',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling saved status: $e');
    }
  }

  Future<void> _shareArticle() async {
    try {
      final title = _article.title;
      final url = _article.url;
      final source = _article.source;

      await Share.share('$title\n\nShared from $source\n$url', subject: title);

      // Track share in analytics
      // _analyticsService.trackShare(_article.id);
    } catch (e) {
      debugPrint('Error sharing article: $e');
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = ModalRoute.of(context)!.settings.arguments as Article;

    // Better text formatting that preserves whole sentences
    final formattedContent =
        article.content.isNotEmpty ? article.content : article.excerpt;

    // Clean the text by removing HTML and converting entities
    String cleanedText =
        formattedContent
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .trim();

    // Insert double line breaks after sentences for better visual separation
    cleanedText = cleanedText.replaceAllMapped(
      RegExp(r'([.!?])\s+'),
      (match) => '${match[1]} ',
    );
    cleanedText = cleanedText.replaceAll('\n', ' ');

    // Single unified text approach - no splitting into paragraphs
    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
        actions: [
          // Bookmark button
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? const Color(0xFFd2982a) : Colors.grey,
            ),
            onPressed: _toggleSaved,
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFd2982a)),
            onPressed: _shareArticle,
          ),
          // Open in browser button
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Color(0xFFd2982a)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          WebViewScreen(url: article.url, title: article.title),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured image
                Stack(
                  children: [
                    // Article image
                    Hero(
                      tag: 'article_image_${article.id}',
                      child: CachedNetworkImage(
                        imageUrl: article.imageUrl,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget:
                            (context, url, error) => Container(
                              height: 240,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white70,
                              ),
                            ),
                      ),
                    ),

                    // Gradient overlay for text readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [
                              0.5,
                              1.0,
                            ], // Adjust gradient to start lower
                          ),
                        ),
                      ),
                    ),

                    // Article title - ADJUSTED POSITION AND SPACING
                    Positioned(
                      bottom:
                          16, // Was likely 24 or higher before - moved closer to bottom
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height:
                                  1.0, // Reduced from likely 1.4 or 1.5 to tighten sentence spacing
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 2.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag if available
                      if (article.categories.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children:
                              article.categories.take(2).map((category) {
                                return Chip(
                                  label: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFd2982a),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                        ),

                      const SizedBox(height: 12),

                      // Article title
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d2c31),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Author and date
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${article.author} • ${DateFormat('MMMM d, yyyy').format(article.publishDate)}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Article content as a single text widget with proper styling
                      Text(
                        cleanedText,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Color(0xFF2d2c31),
                        ),
                        textAlign: TextAlign.justify,
                      ),

                      const SizedBox(height: 24),

                      // First banner ad
                      const AdBanner(
                        adType: AdType.bannerAd,
                        height: 120,
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),

                      const SizedBox(height: 24),

                      // "Read article on website" button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WebViewScreen(
                                      url: article.url,
                                      title: article.title,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd2982a),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'READ ARTICLE ON WEBSITE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Related articles section
                      if (_relatedArticles.isNotEmpty) ...[
                        const Divider(height: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Related Articles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d2c31),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._relatedArticles.map(
                          (relatedArticle) =>
                              _buildRelatedArticleItem(relatedArticle),
                        ),

                        // Add second banner ad after related articles
                        const SizedBox(height: 24),
                        const AdBanner(
                          adType: AdType.bannerAd,
                          height: 120,
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ] else if (_isLoadingRelated) ...[
                        const Divider(height: 32),
                      ],

                      const SizedBox(height: 16),

                      // Bottom spacing
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scroll indicator
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: _scrollProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFd2982a),
                ),
                minHeight: 3,
              ),
            ),
          ),

          // Scroll to top button
          if (_showToTopButton)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFFd2982a),
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/news');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/weather');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/events');
              break;
          }
        },
      ),
    );
  }

  Widget _buildRelatedArticleItem(Article article) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(),
            settings: RouteSettings(arguments: article),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
              ),
            ),
            const SizedBox(width: 12),

            // Title and metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(article.publishDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
