import 'package:intl/intl.dart'; // Make sure to add this import

class Article {
  final String title;
  final String author;
  final DateTime publishDate;
  final String imageUrl;
  final String link;
  final String excerpt;
  final List<String> categories;

  Article({
    required this.title,
    required this.author,
    required this.publishDate,
    required this.imageUrl,
    required this.link,
    required this.excerpt,
    this.categories = const [],
  });

  // Helper method to parse RSS dates
  static DateTime _parseRssDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    try {
      // Try to parse standard format first
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        // Try RFC 822 format used by most RSS feeds
        // Example: "Tue, 25 Mar 2025 16:16:17 +0000"
        final dateFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss Z", "en_US");
        return dateFormat.parse(dateString);
      } catch (e) {
        print('Failed to parse date: $dateString - $e');
        return DateTime.now();
      }
    }
  }

  // Factory constructor to parse RSS data
  factory Article.fromRssItem(dynamic item) {
    // Extract image URL from media content or use default
    String imageUrl = 'assets/images/Default.jpeg';

    try {
      // Check for image in the media content
      if (item.media != null &&
          item.media.contents != null &&
          item.media.contents.isNotEmpty) {
        imageUrl = item.media.contents.first.url ?? imageUrl;
      }
      // Also check for image in enclosure (common in RSS)
      else if (item.enclosure != null && item.enclosure.url != null) {
        imageUrl = item.enclosure.url;
      }
    } catch (e) {
      print('Error extracting image: $e');
    }

    // Clean up description/excerpt by removing HTML tags
    String excerpt = item.description ?? 'No description available';
    excerpt = excerpt.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags

    // Handle categories safely
    List<String> categories = [];
    try {
      if (item.categories != null) {
        categories =
            item.categories.map<String>((cat) {
              // Handle different RSS feed formats for categories
              if (cat.value != null) {
                return cat.value.toString();
              } else if (cat.domain != null) {
                return cat.domain.toString();
              } else if (cat is String) {
                return cat;
              }
              return 'Uncategorized';
            }).toList();
      }
    } catch (e) {
      print('Error parsing categories: $e');
    }

    return Article(
      title: item.title ?? 'No Title',
      author: item.dc?.creator ?? 'Unknown',
      publishDate: _parseRssDate(item.pubDate),
      excerpt: excerpt,
      imageUrl: imageUrl,
      link: item.link ?? '',
      categories: categories,
    );
  }

  // Returns the excerpt as properly formatted paragraphs
  String get formattedContent {
    if (excerpt.isEmpty) return '';

    // Clean up common RSS/HTML issues
    String content =
        excerpt
            // Replace HTML line breaks with actual line breaks
            .replaceAll(RegExp(r'<br\s*\/?>'), '\n')
            // Replace multiple consecutive line breaks with double line breaks
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            // Replace HTML entities
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            // Remove any remaining HTML tags
            .replaceAll(RegExp(r'<[^>]*>'), '')
            // Trim extra spaces
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();

    // Split into paragraphs and clean up each paragraph
    List<String> paragraphs = content.split('\n\n');
    paragraphs = paragraphs.map((p) => p.trim()).toList();

    // Remove empty paragraphs
    paragraphs.removeWhere((p) => p.isEmpty);

    // Join with double line breaks for proper paragraph separation
    return paragraphs.join('\n\n');
  }
}
