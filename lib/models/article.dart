import 'package:intl/intl.dart';

class Article {
  final String id;
  final String title;
  final String author;
  final DateTime publishDate;
  final String imageUrl;
  final String url; // renamed from 'link' for clarity
  final String content; // full content (for sponsored articles)
  final String excerpt; // short description (used for previews)
  final List<String> categories;
  final bool isSponsored; // flag for sponsored content
  final String linkText; // custom text for CTA button
  final String
  source; // source name (e.g., company name for sponsored articles)

  // Add a getter for backward compatibility
  String get link =>
      url; // This ensures old code using article.link still works

  Article({
    this.id = '',
    required this.title,
    required this.author,
    required this.publishDate,
    required this.imageUrl,
    this.url = '', // renamed from 'link'
    this.content = '', // full content
    this.excerpt = '', // short description
    this.categories = const [],
    this.isSponsored = false,
    this.linkText = 'Read More',
    this.source = '',
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
      content: excerpt, // For RSS items, content is the same as excerpt
      imageUrl: imageUrl,
      url: item.link ?? '',
      categories: categories,
      isSponsored: false, // RSS feeds are not sponsored content
      source: item.source?.title ?? 'News Feed',
    );
  }

  // Factory constructor for Firestore sponsored articles
  factory Article.fromFirestore(String documentId, Map<String, dynamic> data) {
    return Article(
      id: documentId,
      title: data['title'] ?? 'No Title',
      author: data['authorName'] ?? 'Sponsored',
      publishDate: data['publishedAt']?.toDate() ?? DateTime.now(),
      imageUrl: data['headerImageUrl'] ?? 'assets/images/Default.jpeg',
      content: data['content'] ?? '',
      excerpt:
          data['content'] != null && data['content'].length > 150
              ? '${data['content'].substring(0, 150)}...'
              : data['content'] ?? '',
      url: data['ctaLink'] ?? '',
      linkText: data['ctaText'] ?? 'Learn More',
      isSponsored: true,
      source: data['companyName'] ?? 'Sponsored Content',
      categories: data['category'] != null ? [data['category']] : ['Sponsored'],
    );
  }

  // Returns the excerpt as properly formatted paragraphs
  String get formattedContent {
    if (content.isNotEmpty) {
      // For sponsored articles with full content
      return _formatText(content);
    } else if (excerpt.isNotEmpty) {
      // For RSS articles with only excerpt
      return _formatText(excerpt);
    }
    return '';
  }

  // Helper method to format text
  String _formatText(String text) {
    // Clean up common RSS/HTML issues
    String cleanedText =
        text
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
    List<String> paragraphs = cleanedText.split('\n\n');
    paragraphs = paragraphs.map((p) => p.trim()).toList();

    // Remove empty paragraphs
    paragraphs.removeWhere((p) => p.isEmpty);

    // Join with double line breaks for proper paragraph separation
    return paragraphs.join('\n\n');
  }

  // Helper method to get a shorter excerpt for previews
  String get shortExcerpt {
    if (excerpt.length <= 100) return excerpt;
    return '${excerpt.substring(0, 97)}...';
  }
}
