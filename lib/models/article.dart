import 'package:intl/intl.dart';

class Article {
  final String? id;
  final String? guid;
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final DateTime publishDate;
  final String? category;
  final String? author;
  final String? excerpt;
  final String? content;
  final String? linkText;
  final bool isSponsored;
  final String? source;

  Article({
    this.id,
    this.guid,
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.publishDate,
    this.category,
    this.author,
    this.excerpt,
    this.content,
    this.linkText,
    this.isSponsored = false,
    this.source,
  });

  // Helper method to get unique identifier
  String get uniqueId => guid ?? id ?? url;

  // Add this computed property for article_detail_screen.dart
  String get formattedContent {
    // Use content if available, otherwise use description
    final textToFormat = content ?? description;

    // Clean up HTML tags if present
    final withoutHtml = textToFormat.replaceAll(RegExp(r'<[^>]*>'), '');

    // Fix common formatting issues
    return withoutHtml
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  // Add this to your Article model
  String get safeContent {
    // Remove potentially harmful tags
    return content?.replaceAll(
          RegExp(r'<script.*?</script>|<iframe.*?</iframe>'),
          '',
        ) ??
        '';
  }

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
      // Extract image from description if needed
      else if (item.description != null) {
        final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
        final match = imgRegex.firstMatch(item.description);
        if (match != null && match.groupCount >= 1) {
          imageUrl = match.group(1) ?? imageUrl;
        }
      }
    } catch (e) {
      print('Error extracting image: $e');
    }

    // Clean up description by removing HTML tags
    String description = item.description ?? 'No description available';
    description = description.replaceAll(RegExp(r'<[^>]*>'), '');

    return Article(
      title: item.title ?? 'No Title',
      description: description,
      publishDate: _parseRssDate(item.pubDate),
      imageUrl: imageUrl,
      url: item.link ?? '',
      guid: item.guid ?? item.link ?? '', // Use link as fallback
      category: item.categories?.first?.value ?? 'Uncategorized',
      author: item.author,
      // Remove excerpt: item.excerpt, line
      content: item.content?.value, // Use content.value instead
      linkText: null, // No direct equivalent in RSS
      isSponsored: false,
      source: null,
    );
  }

  // Factory constructor for Firestore sponsored articles
  factory Article.fromFirestore(String documentId, Map<String, dynamic> data) {
    return Article(
      id: documentId,
      guid: data['guid'] ?? data['ctaLink'] ?? '', // Use link as fallback
      title: data['title'] ?? 'No Title',
      description: data['content'] ?? '',
      publishDate: data['publishedAt']?.toDate() ?? DateTime.now(),
      imageUrl: data['headerImageUrl'] ?? 'assets/images/Default.jpeg',
      url: data['ctaLink'] ?? '',
      category: data['category'] ?? 'Sponsored',
      author: data['author'],
      excerpt: data['excerpt'],
      content: data['content'],
      linkText: data['linkText'],
      isSponsored: data['isSponsored'] ?? false,
      source: data['source'],
    );
  }

  // Convert to and from JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guid': guid,
      'title': title,
      'description': description,
      'url': url,
      'imageUrl': imageUrl,
      'publishDate': publishDate.toIso8601String(),
      'category': category,
      'author': author,
      'excerpt': excerpt,
      'content': content,
      'linkText': linkText,
      'isSponsored': isSponsored,
      'source': source,
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      publishDate:
          json['publishDate'] != null
              ? DateTime.parse(json['publishDate'])
              : DateTime.now(),
      guid: json['guid'] ?? '',
      author: json['author'] ?? 'Neuse News',
      content: json['content'] ?? '',
      // Don't include excerpt here
    );
  }

  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }
}
