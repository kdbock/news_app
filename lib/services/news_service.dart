import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import 'package:flutter/foundation.dart'; // Add for debugPrint
import '../models/article.dart';
import 'dart:math'; // For min function

class NewsService {
  // Generic method to fetch news by any URL with improved error handling
  Future<List<Article>> fetchNewsByUrl(
    String url, {
    int skip = 0,
    int take = 10,
  }) async {
    try {
      debugPrint('Fetching news from: $url'); // Use debugPrint instead of print

      // Properly encode URLs with spaces and special characters
      final encodedUrl = Uri.encodeFull(url);
      final response = await http.get(Uri.parse(encodedUrl));

      if (response.statusCode == 200) {
        debugPrint('Successfully loaded feed from: $url');
        try {
          // If it's sports feed, use special handling
          if (url.contains('neusenewssports')) {
            return parseRssFeed(response.body, isSportsFeed: true);
          }

          final feed = RssFeed.parse(response.body);
          final allArticles =
              feed.items.map((item) => Article.fromRssItem(item)).toList();
          debugPrint('Parsed ${allArticles.length} articles from $url');
          // Apply skip and take to limit results
          return allArticles.skip(skip).take(take).toList();
        } catch (parseError) {
          debugPrint('Error parsing RSS feed from $url: $parseError');
          debugPrint(
            'Response body: ${response.body.substring(0, min(200, response.body.length))}...',
          );
          throw Exception('Failed to parse feed data: $parseError');
        }
      } else {
        debugPrint(
          'Failed to load feed from $url: Status code ${response.statusCode}',
        );
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching news from $url: $e');
      // Return empty list instead of throwing to prevent the whole Future.wait from failing
      return [];
    }
  }

  // Add RSS parsing capabilities within the service
  List<Article> parseRssFeed(
    String xmlData, {
    bool isSportsFeed = false,
    int skip = 0,
    int take = 20,
  }) {
    try {
      // More aggressive XML cleanup specifically for problematic feeds
      String cleanedXml = xmlData.trim();

      // First, handle XML declaration and comments
      if (cleanedXml.startsWith("<?xml")) {
        // Find where the actual content begins after declaration and comments
        final rssStart = cleanedXml.indexOf("<rss");
        if (rssStart > 0) {
          cleanedXml = cleanedXml.substring(rssStart);
          debugPrint('Removed XML declaration and comments');
        }
      }

      try {
        // First parsing attempt
        final feed = RssFeed.parse(cleanedXml);

        // Verify we have items
        if (feed.items.isEmpty) {
          debugPrint('Warning: RSS feed parsed but contains no items');
          return [];
        }

        debugPrint('Successfully parsed feed with ${feed.items.length} items');

        // Process items
        return feed.items
            .skip(skip)
            .take(take)
            .map((item) {
              try {
                // Extract image URL
                String imageUrl = _extractImageUrl(item);
                if (imageUrl.isEmpty) {
                  imageUrl = 'assets/images/Default.jpeg';
                }

                return Article(
                  title: item.title ?? 'Untitled',
                  description: item.description ?? '',
                  url: item.link ?? '',
                  imageUrl: imageUrl,
                  publishDate:
                      item.pubDate != null
                          ? _parseRssDate(item.pubDate!)
                          : DateTime.now(),
                  guid: item.guid ?? item.link ?? DateTime.now().toString(),
                  author: item.author ?? 'Neuse News',
                  content: item.content?.value ?? item.description ?? '',
                  // No excerpt field
                );
              } catch (itemError) {
                debugPrint('Error processing RSS item: $itemError');
                return null;
              }
            })
            .where((article) => article != null)
            .cast<Article>()
            .toList();
      } catch (parseError) {
        // First parse attempt failed, try alternate approach for sports feed
        if (isSportsFeed) {
          debugPrint(
            'First parsing attempt failed, trying alternative approach: $parseError',
          );
          return _parseSquarespaceSportsFeed(
            cleanedXml,
            skip: skip,
            take: take,
          );
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error parsing RSS feed: $e');
      if (isSportsFeed) {
        return _generateFallbackSportsArticles();
      }
      return [];
    }
  }

  // Extract image URL from RSS item
  String _extractImageUrl(RssItem item) {
    try {
      // Check for enclosure images first (standard RSS)
      if (item.enclosure != null &&
          item.enclosure!.url != null &&
          item.enclosure!.url!.isNotEmpty) {
        return item.enclosure!.url!;
      }

      // Check for media content
      if (item.media != null &&
          item.media!.contents.isNotEmpty) {
        for (final content in item.media!.contents) {
          if (content.url != null && content.url!.isNotEmpty) {
            return content.url!;
          }
        }
      }

      // Check for images in description HTML - most common in Squarespace
      if (item.description != null) {
        // Look for both src and data-src attributes (Squarespace specific)
        final imgRegex = RegExp(r'<img[^>]+(src|data-src)="([^">]+)"');
        final matches = imgRegex.allMatches(item.description!);

        for (final match in matches) {
          final url = match.group(2);
          if (url != null &&
              url.isNotEmpty &&
              (url.startsWith('http') || url.startsWith('//'))) {
            return url.startsWith('//') ? 'https:$url' : url;
          }
        }
      }

      // Check for images in content
      if (item.content != null) {
        final imgRegex = RegExp(r'<img[^>]+(src|data-src)="([^">]+)"');
        final matches = imgRegex.allMatches(item.content!.value);

        for (final match in matches) {
          final url = match.group(2);
          if (url != null &&
              url.isNotEmpty &&
              (url.startsWith('http') || url.startsWith('//'))) {
            return url.startsWith('//') ? 'https:$url' : url;
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting image: $e');
    }

    // Default image if nothing is found
    return 'https://neusenews.com/wp-content/uploads/2023/01/default-image.jpg';
  }

  // Manual parser for problematic feeds
  List<Article> _parseSquarespaceSportsFeed(
    String xmlData, {
    int skip = 0,
    int take = 20,
  }) {
    try {
      // Manually extract items using regex for severely malformed feeds
      final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
      final matches = itemRegex.allMatches(xmlData);

      debugPrint('Found ${matches.length} items using regex fallback');

      if (matches.isEmpty) {
        return _generateFallbackSportsArticles();
      }

      List<Article> articles = [];
      int count = 0;

      for (var match in matches) {
        if (count >= skip + take) break;
        if (count < skip) {
          count++;
          continue;
        }

        try {
          final itemXml = match.group(1) ?? '';

          // Extract the basic fields using regex
          final titleMatch = RegExp(
            r'<title>(.*?)</title>',
          ).firstMatch(itemXml);
          final linkMatch = RegExp(r'<link>(.*?)</link>').firstMatch(itemXml);
          final descMatch = RegExp(
            r'<description>(.*?)</description>',
            dotAll: true,
          ).firstMatch(itemXml);
          final dateMatch = RegExp(
            r'<pubDate>(.*?)</pubDate>',
          ).firstMatch(itemXml);

          // Create article from extracted data
          final article = Article(
            title: _cleanHtml(titleMatch?.group(1) ?? 'Sports Update'),
            url:
                linkMatch?.group(1)?.trim() ??
                'https://www.neusenewssports.com',
            description: _cleanHtml(descMatch?.group(1) ?? ''),
            imageUrl:
                _extractImageFromHtml(descMatch?.group(1) ?? '') ??
                'assets/images/Default.jpeg',
            publishDate: _parseDate(dateMatch?.group(1) ?? ''),
            guid: linkMatch?.group(1)?.trim() ?? DateTime.now().toString(),
            author: 'Neuse Sports',
            content: _cleanHtml(descMatch?.group(1) ?? ''),
          );

          articles.add(article);
          count++;
        } catch (itemError) {
          debugPrint('Error extracting item data: $itemError');
        }
      }

      return articles;
    } catch (e) {
      debugPrint('Error in fallback sports parser: $e');
      return _generateFallbackSportsArticles();
    }
  }

  // Helper to clean HTML content
  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('  ', ' ')
        .trim();
  }

  // Helper to extract image URL from HTML content
  String? _extractImageFromHtml(String html) {
    final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(html);
    return imgMatch?.group(1);
  }

  // Helper to parse date
  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      // Return current date if parsing fails
      return DateTime.now();
    }
  }

  // Generate fallback content for sports feed
  List<Article> _generateFallbackSportsArticles() {
    debugPrint('Generating fallback sports articles');
    return [
      Article(
        title: 'Latest Sports Updates',
        description:
            'Visit Neuse News Sports for the latest local sports coverage.',
        url: 'https://www.neusenewssports.com',
        imageUrl: 'assets/images/Default.jpeg',
        publishDate: DateTime.now(),
        guid: 'fallback-sports-1',
        author: 'Neuse Sports',
        content: 'Visit our website for the latest in local sports coverage.',
      ),
      Article(
        title: 'Local Sports Coverage',
        description: 'Check back soon for updated sports news and scores.',
        url: 'https://www.neusenewssports.com',
        imageUrl: 'assets/images/Default.jpeg',
        publishDate: DateTime.now().subtract(const Duration(days: 1)),
        guid: 'fallback-sports-2',
        author: 'Neuse Sports',
        content: 'Our team is working to bring you the latest sports updates.',
      ),
    ];
  }

  // Category-specific methods with proper URL encoding
  Future<List<Article>> fetchLocalNews() {
    return fetchNewsByUrl('https://www.neusenews.com/index?format=rss');
  }

  Future<List<Article>> fetchPolitics() {
    return fetchNewsByUrl('https://www.ncpoliticalnews.com/news?format=rss');
  }

  Future<List<Article>> fetchSports() async {
    try {
      final url = 'https://www.neusenewssports.com/news-1?format=rss';

      // Add retry logic for problematic feeds
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('Fetching sports feed (attempt $attempt)');
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            // Check response length for debugging
            debugPrint(
              'Sports feed response length: ${response.body.length} bytes',
            );
            final articles = parseRssFeed(response.body, isSportsFeed: true);

            // If we got articles, return them
            if (articles.isNotEmpty) {
              debugPrint(
                'Successfully parsed ${articles.length} sports articles',
              );
              return articles;
            }
          }

          // Wait briefly before retry
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } catch (e) {
          debugPrint('Error in sports fetch attempt $attempt: $e');

          // Only wait between retries, not after the last attempt
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }

      // If all attempts failed, return fallback content
      return _generateFallbackSportsArticles();
    } catch (e) {
      debugPrint('Error fetching sports news: $e');
      return [];
    }
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

  // Add this after your other helper methods

  // Helper function to parse RSS dates with proper error handling
  DateTime _parseRssDate(String dateStr) {
    try {
      // Try built-in parser first (works for ISO format)
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Handle RFC 822 format (standard RSS date format)
        // Example: "Thu, 03 Apr 2025 04:38:16 +0000"
        final regex = RegExp(
          r'(\w+), (\d+) (\w+) (\d{4}) (\d{2}):(\d{2}):(\d{2}) ([\+\-]\d{4})',
        );
        final match = regex.firstMatch(dateStr);

        if (match != null) {
          final day = int.parse(match.group(2)!);
          final monthStr = match.group(3)!;
          final year = int.parse(match.group(4)!);
          final hour = int.parse(match.group(5)!);
          final minute = int.parse(match.group(6)!);
          final second = int.parse(match.group(7)!);

          // Convert month name to number
          final months = {
            'Jan': 1,
            'Feb': 2,
            'Mar': 3,
            'Apr': 4,
            'May': 5,
            'Jun': 6,
            'Jul': 7,
            'Aug': 8,
            'Sep': 9,
            'Oct': 10,
            'Nov': 11,
            'Dec': 12,
          };

          final month = months[monthStr] ?? 1;

          return DateTime(year, month, day, hour, minute, second);
        }

        // If regex fails, return current date
        debugPrint('Date parsing failed for: $dateStr');
        return DateTime.now();
      } catch (e) {
        debugPrint('Error parsing date "$dateStr": $e');
        return DateTime.now();
      }
    }
  }
}
