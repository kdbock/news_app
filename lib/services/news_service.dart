import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import '../models/article.dart';

class NewsService {
  // Generic method to fetch news by any URL with improved error handling
  Future<List<Article>> fetchNewsByUrl(String url) async {
    try {
      print('Fetching news from: $url');

      // Properly encode URLs with spaces and special characters
      final encodedUrl = Uri.encodeFull(url);
      final response = await http.get(Uri.parse(encodedUrl));

      if (response.statusCode == 200) {
        print('Successfully loaded feed from: $url');
        try {
          final feed = RssFeed.parse(response.body);
          final articles =
              feed.items.map((item) => Article.fromRssItem(item)).toList();
          print('Parsed ${articles.length} articles from $url');
          return articles;
        } catch (parseError) {
          print('Error parsing RSS feed from $url: $parseError');
          print(
            'Response body: ${response.body.substring(0, 200)}...',
          ); // Print first 200 chars for debugging
          throw Exception('Failed to parse feed data: $parseError');
        }
      } else {
        print(
          'Failed to load feed from $url: Status code ${response.statusCode}',
        );
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news from $url: $e');
      // Return empty list instead of throwing to prevent the whole Future.wait from failing
      return [];
    }
  }

  // Category-specific methods with proper URL encoding
  Future<List<Article>> fetchLocalNews() {
    return fetchNewsByUrl('https://www.neusenews.com/index?format=rss');
  }

  Future<List<Article>> fetchPolitics() {
    return fetchNewsByUrl('https://www.ncpoliticalnews.com/news?format=rss');
  }

  Future<List<Article>> fetchSports() {
    return fetchNewsByUrl('https://www.neusenewssports.com/news-1?format=rss');
  }

  Future<List<Article>> fetchColumns() {
    // Notice the URL encoding for the space
    return fetchNewsByUrl(
      'https://www.neusenews.com/index/category/Columns?format=rss',
    );
  }

  Future<List<Article>> fetchMattersOfRecord() {
    // Notice proper handling of the plus character
    return fetchNewsByUrl(
      'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
    );
  }

  Future<List<Article>> fetchObituaries() {
    return fetchNewsByUrl(
      'https://www.neusenews.com/index/category/Obituaries?format=rss',
    );
  }

  Future<List<Article>> fetchPublicNotices() {
    // Notice proper handling of the plus character
    return fetchNewsByUrl(
      'https://www.neusenews.com/index/category/Public+Notices?format=rss',
    );
  }

  Future<List<Article>> fetchClassifieds() {
    return fetchNewsByUrl(
      'https://www.neusenews.com/index/category/Classifieds?format=rss',
    );
  }
}
