import 'package:flutter/material.dart';
import 'package:news_app/models/article.dart';
import 'package:news_app/screens/web_view_screen.dart';

class NewsSearchDelegate extends SearchDelegate<String> {
  final List<Article> localNews;
  final List<Article> sportsNews;
  final List<Article> columnsNews;
  final List<Article> obituariesNews;

  // Combined list of all articles for searching
  late final List<Article> _allArticles;

  NewsSearchDelegate(
    this.localNews,
    this.sportsNews,
    this.columnsNews,
    this.obituariesNews,
  ) {
    // Combine all articles into one list for searching
    _allArticles = [
      ...localNews,
      ...sportsNews,
      ...columnsNews,
      ...obituariesNews,
    ];
  }

  @override
  String get searchFieldLabel => 'Search news...';

  @override
  TextStyle get searchFieldStyle => const TextStyle(fontSize: 16);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = super.appBarTheme(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFFd2982a)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchArticles(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final article = results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading:
              article.imageUrl.startsWith('http')
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        article.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Image.asset(
                              'assets/images/Default.jpeg',
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                  )
                  : const Icon(Icons.article),
          title: Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${article.author} · ${_formatDate(article.publishDate)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        WebViewScreen(url: article.link, title: article.title),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for news articles',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final results = _searchArticles(query);

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results for "$query"',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final article = results[index];
        return ListTile(
          leading: const Icon(Icons.article),
          title: Text(
            article.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            query = article.title;
            showResults(context);
          },
        );
      },
    );
  }

  List<Article> _searchArticles(String query) {
    return _allArticles.where((article) {
      final title = article.title.toLowerCase();
      final author = article.author.toLowerCase();
      final content = article.excerpt.toLowerCase();
      final searchLower = query.toLowerCase();

      return title.contains(searchLower) ||
          author.contains(searchLower) ||
          content.contains(searchLower);
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }

    final month =
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][date.month - 1];

    return '$month ${date.day}';
  }
}
