import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import '../models/article.dart';

class NewsService {
  // Generic method to fetch news by any URL
  Future<List<Article>> fetchNewsByUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        return feed.items.map((item) => Article.fromRssItem(item)).toList();
      } else {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Error fetching news data: $e');
    }
  }

  // Category-specific methods that use the generic method
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
    return fetchNewsByUrl(
      'https://www.neusenews.com/index/category/Columns?format=rss',
    );
  }

  Future<List<Article>> fetchMattersOfRecord() {
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
