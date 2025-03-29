import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for SystemChrome
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card.dart';
// Make sure this is in pubspec.yaml
// Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  String _currentCategory = 'All News';

  // Store the source of each article for filtering
  final Map<String, String> _articleSources = {};

  @override
  void initState() {
    super.initState();
    _loadAllNews();

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

  Future<void> _loadAllNews() async {
    setState(() => _isLoading = true);

    try {
      // Load all three feeds
      final localNews = await _newsService.fetchLocalNews();
      final politicsNews = await _newsService.fetchNewsByUrl(
        'https://www.ncpoliticalnews.com/news?format=rss',
      );
      final sportsNews = await _newsService.fetchNewsByUrl(
        'https://www.neusenewssports.com/news-1?format=rss',
      );

      if (mounted) {
        // Tag each article with its source
        for (var article in localNews) {
          _articleSources[article.url] =
              'Local News'; // Changed from article.link
        }
        for (var article in politicsNews) {
          _articleSources[article.url] =
              'NC Politics'; // Changed from article.link
        }
        for (var article in sportsNews) {
          _articleSources[article.url] = 'Sports'; // Changed from article.link
        }

        // Combine all articles
        List<Article> allArticles = [
          ...localNews,
          ...politicsNews,
          ...sportsNews,
        ];

        // Sort by publish date (newest first)
        allArticles.sort((a, b) => b.publishDate.compareTo(a.publishDate));

        setState(() {
          _articles = allArticles;
          _isLoading = false;
          _currentCategory = 'All News';
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

  Future<void> _loadCategoryNews(String category) async {
    setState(() => _isLoading = true);

    try {
      String url;
      switch (category) {
        case 'Local News':
          url = 'https://www.neusenews.com/index?format=rss';
          break;
        case 'NC Politics':
          url = 'https://www.ncpoliticalnews.com/news?format=rss';
          break;
        case 'Sports':
          url = 'https://www.neusenewssports.com/news-1?format=rss';
          break;
        default:
          // Load all feeds if "All News" selected
          _loadAllNews();
          return;
      }

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
          onRefresh: _loadAllNews,
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

              // Source indicators
              if (_currentCategory == 'All News')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildSourceIndicator('Local News', Colors.blue),
                      const SizedBox(width: 12),
                      _buildSourceIndicator('NC Politics', Colors.red),
                      const SizedBox(width: 12),
                      _buildSourceIndicator('Sports', Colors.green),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Article list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) {
                    final article = _articles[index];
                    return NewsCard(
                      article: article,
                      onReadMore: () => _onArticleTap(article),
                      // Add source indicator if showing all news
                      sourceTag:
                          _currentCategory == 'All News'
                              ? _articleSources[article
                                  .url] // Changed from article.link
                              : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildSourceIndicator(String source, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(source, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
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
            'News Sources',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildCategoryChip('All News'),
              _buildCategoryChip('Local News'),
              _buildCategoryChip('NC Politics'),
              _buildCategoryChip('Sports'),
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
        if (category == 'All News') {
          _loadAllNews();
        } else {
          _loadCategoryNews(category);
        }
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
