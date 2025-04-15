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
  final bool isRead; // track read status
  final Map<String, double>? categoryScores;
  final String? primaryCategory;
  final DateTime publishedAt; // Add this property

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
    this.isRead = false,
    this.categoryScores,
    this.primaryCategory,
    required this.publishedAt, // Initialize it
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
        // Try to parse RSS date format (RFC 822)
        // Convert to a format that DateTime.parse can handle
        final formats = [
          'EEE, dd MMM yyyy HH:mm:ss Z', // Standard RSS
          'dd MMM yyyy HH:mm:ss Z', // Some RSS feeds omit day name
          'EEE, dd MMM yyyy HH:mm:ss', // Some RSS feeds omit timezone
          'yyyy-MM-ddTHH:mm:ssZ', // ISO 8601
          'yyyy-MM-dd HH:mm:ss', // Basic format
        ];

        for (final format in formats) {
          try {
            return DateFormat(format).parse(dateString);
          } catch (_) {
            // Try next format
          }
        }

        // If all format parses fail, return current date
        return DateTime.now();
      } catch (_) {
        // If all else fails, return current date
        return DateTime.now();
      }
    }
  }

  // Factory constructor to parse RSS data
  factory Article.fromRssItem(dynamic item) {
    // Extract image URL from media content or use default
    String imageUrl = 'assets/images/Default.jpeg';

    try {
      // Try to get image from media:content
      if (item.media?.contents != null && item.media!.contents.isNotEmpty) {
        final mediaContent = item.media!.contents.first;
        if (mediaContent.url != null && mediaContent.url.isNotEmpty) {
          imageUrl = mediaContent.url;
        }
      }
      // If no media:content, try enclosure
      else if (item.enclosure != null && item.enclosure.url != null) {
        imageUrl = item.enclosure.url;
      }
      // If still no image, try to find an image in the description
      else if (item.description != null) {
        final imgRegExp = RegExp(r'<img[^>]+src="([^">]+)"');
        final match = imgRegExp.firstMatch(item.description);
        if (match != null && match.groupCount >= 1) {
          imageUrl = match.group(1)!;
        }
      }
    } catch (e) {
      // If any error occurs while extracting the image, use the default
    }

    // Clean up description/excerpt by removing HTML tags
    String excerpt = item.description ?? 'No description available';
    excerpt = excerpt.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags

    // Handle categories safely
    List<String> categories = [];
    try {
      if (item.categories != null) {
        categories = item.categories.map<String>((cat) => cat.value).toList();
      }
    } catch (e) {
      // If categories can't be parsed, leave as empty list
    }

    return Article(
      id: item.guid ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: item.title ?? 'Untitled Article',
      author: item.author ?? item.dc?.creator ?? 'Staff Reporter',
      publishDate: _parseRssDate(item.pubDate),
      imageUrl: imageUrl,
      url: item.link ?? '',
      excerpt: excerpt,
      categories: categories,
      isSponsored: categories.any(
        (cat) => cat.toLowerCase().contains('sponsor'),
      ),
      source: _determineSource(item),
      publishedAt: _parseRssDate(item.pubDate), // Initialize it
    );
  }

  // Helper to determine source from feed item
  static String _determineSource(dynamic item) {
    try {
      if (item.dc?.creator != null) return item.dc!.creator;
      if (item.author != null) return item.author;

      // Check if it's from specific feeds we know
      final link = item.link ?? '';
      if (link.contains('neusenewssports.com')) return 'Sports';
      if (link.contains('ncpoliticalnews.com')) return 'NC Politics';

      return 'Neuse News';
    } catch (_) {
      return 'Neuse News';
    }
  }

  // Factory constructor for Firestore sponsored articles
  factory Article.fromFirestore(String documentId, Map<String, dynamic> data) {
    return Article(
      id: documentId,
      title: data['title'] ?? 'Untitled Article',
      author: data['authorName'] ?? 'Sponsor',
      publishDate: data['publishedAt']?.toDate() ?? DateTime.now(),
      imageUrl: data['headerImageUrl'] ?? 'assets/images/Default.jpeg',
      url: data['ctaLink'] ?? '',
      content: data['content'] ?? '',
      excerpt: data['excerpt'] ?? '',
      isSponsored: true,
      linkText: data['ctaText'] ?? 'Learn More',
      source: data['companyName'] ?? 'Sponsored Content',
      publishedAt:
          data['publishedAt']?.toDate() ?? DateTime.now(), // Initialize it
    );
  }

  // JSON serialization for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publishDate': publishDate.toIso8601String(),
      'imageUrl': imageUrl,
      'url': url,
      'content': content,
      'excerpt': excerpt,
      'categories': categories,
      'isSponsored': isSponsored,
      'linkText': linkText,
      'source': source,
      'isRead': isRead,
      'categoryScores': categoryScores,
      'primaryCategory': primaryCategory,
      'publishedAt': publishedAt.toIso8601String(), // Add this property
    };
  }

  // JSON deserialization for caching
  factory Article.fromJson(Map<String, dynamic> json) {
    List<String> categoryList = [];
    if (json['categories'] != null) {
      categoryList = List<String>.from(json['categories']);
    }

    Map<String, double>? scores;
    if (json['categoryScores'] != null) {
      scores = Map<String, double>.from(json['categoryScores']);
    }

    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Article',
      author: json['author'] ?? 'Unknown Author',
      publishDate: DateTime.parse(json['publishDate']),
      imageUrl: json['imageUrl'] ?? 'assets/images/Default.jpeg',
      url: json['url'] ?? '',
      content: json['content'] ?? '',
      excerpt: json['excerpt'] ?? '',
      categories: categoryList,
      isSponsored: json['isSponsored'] ?? false,
      linkText: json['linkText'] ?? 'Read More',
      source: json['source'] ?? 'Neuse News',
      isRead: json['isRead'] ?? false,
      categoryScores: scores,
      primaryCategory: json['primaryCategory'],
      publishedAt: DateTime.parse(
        json['publishedAt'] as String,
      ), // Parse the date
    );
  }

  // Returns the excerpt as properly formatted paragraphs
  String get formattedContent {
    if (content.isNotEmpty) {
      return _formatText(content);
    } else if (excerpt.isNotEmpty) {
      return _formatText(excerpt);
    }
    return '';
  }

  // Create a copy of the article with modified properties
  Article copyWith({
    String? id,
    String? title,
    String? author,
    DateTime? publishDate,
    String? imageUrl,
    String? url,
    String? content,
    String? excerpt,
    List<String>? categories,
    bool? isSponsored,
    String? linkText,
    String? source,
    bool? isRead,
    DateTime? publishedAt, // Add this property
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publishDate: publishDate ?? this.publishDate,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      categories: categories ?? this.categories,
      isSponsored: isSponsored ?? this.isSponsored,
      linkText: linkText ?? this.linkText,
      source: source ?? this.source,
      isRead: isRead ?? this.isRead,
      publishedAt: publishedAt ?? this.publishedAt, // Initialize it
    );
  }

  // Helper method to format text
  String _formatText(String text) {
    // Clean up common RSS/HTML issues
    String cleanedText = text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('\r', ''); // Clean up newlines

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
