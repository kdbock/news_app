import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for SystemChrome
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/article.dart';
import 'package:news_app/widgets/news_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Make sure this is in pubspec.yaml
import 'package:news_app/screens/dashboard_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  String _currentCategory = 'Local News';
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNews();

    // Use this method to ensure status bar is always white
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white, // Completely white
          statusBarBrightness: Brightness.light, // For iOS
          statusBarIconBrightness: Brightness.dark, // For Android
        ),
      );
    });
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);

    try {
      final articles = await _newsService.fetchLocalNews();
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading news: $e')));
      }
    }
  }

  Future<void> _loadCategoryNews(String category, String url) async {
    setState(() => _isLoading = true);

    try {
      final articles = await _newsService.fetchNewsByUrl(url);
      if (mounted) {
        setState(() {
          _articles = articles;
          _currentCategory = category;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading $category: $e')));
      }
    }
  }

  void _onArticleTap(Article article) {
    // Navigate to article detail page
    Navigator.pushNamed(context, '/article', arguments: article);
  }

  @override
  Widget build(BuildContext context) {
    // Return just the content without Scaffold, AppBar or BottomNavigationBar
    return _isLoading
        ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFd2982a)),
        )
        : RefreshIndicator(
          onRefresh: _loadNews,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentCategory,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d2c31),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.filter_list,
                        color: Color(0xFFd2982a),
                        size: 20,
                      ),
                      label: const Text(
                        'Filter',
                        style: TextStyle(
                          color: Color(0xFFd2982a),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => _buildCategoriesSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Article list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) {
                    return NewsCard(
                      article: _articles[index],
                      onReadMore: () => _onArticleTap(_articles[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }

  // The helper methods stay the same
  Widget _buildCategoriesSheet() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'News Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildCategoryChip('Local News'),
              _buildCategoryChip('State News'),
              _buildCategoryChip('NC Politics'),
              _buildCategoryChip('Sports'),
              _buildCategoryChip('Columns'),
              _buildCategoryChip('Matters of Record'),
              _buildCategoryChip('Obituaries'),
              _buildCategoryChip('Public Notices'),
              _buildCategoryChip('Classifieds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return ActionChip(
      label: Text(category),
      backgroundColor:
          _currentCategory == category
              ? const Color(0xFFd2982a)
              : Colors.grey[200],
      labelStyle: TextStyle(
        color: _currentCategory == category ? Colors.white : Colors.black,
      ),
      onPressed: () {
        Navigator.pop(context);
        _loadCategoryNews(
          category,
          'https://www.neusenews.com/index?format=rss',
        );
      },
    );
  }
}

// Keep the NewsSearchDelegate but it will now be used from dashboard_screen.dart
class NewsSearchDelegate extends SearchDelegate<String> {
  final List<Article> articles;
  final Function(Article) onArticleTap;

  NewsSearchDelegate(this.articles, this.onArticleTap);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results =
        query.isEmpty
            ? []
            : articles
                .where(
                  (a) =>
                      a.title.toLowerCase().contains(query.toLowerCase()) ||
                      a.excerpt.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

    return results.isEmpty
        ? Center(
          child: Text(
            query.isEmpty ? 'Enter search term' : 'No results found',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )
        : ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            return NewsCard(
              article: results[index],
              onReadMore: () {
                close(context, '');
                onArticleTap(results[index]);
              },
            );
          },
        );
  }
}
