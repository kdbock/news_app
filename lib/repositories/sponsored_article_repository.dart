import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/models/article.dart';

class SponsoredArticleRepository {
  final FirebaseFirestore _firestore;
  
  SponsoredArticleRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
      
  Future<List<Article>> fetchPublishedArticles() async {
    try {
      log('Fetching published sponsored articles...');

      final snapshot = await _firestore
          .collection('sponsored_articles')
          .where('status', isEqualTo: 'published')
          .get();

      log('Found ${snapshot.docs.length} published sponsored articles');

      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<Article> articles = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          DateTime publishDate;
          try {
            publishDate = data['publishedAt']?.toDate() ?? DateTime.now();
          } catch (dateError) {
            log('Error parsing publishedAt date: $dateError, using current date');
            publishDate = DateTime.now();
          }

          final article = Article(
            id: doc.id,
            title: data['title'] ?? 'Sponsored Article',
            excerpt: _createExcerpt(data['content']),
            content: data['content']?.toString() ?? '',
            imageUrl: data['headerImageUrl'] ?? '',
            publishDate: publishDate,
            publishedAt: publishDate,
            author: data['authorName'] ?? 'Sponsor',
            url: data['ctaLink'] ?? '',
            linkText: data['ctaText'] ?? 'Learn More',
            isSponsored: true,
            source: data['companyName'] ?? 'Sponsored Content',
          );

          articles.add(article);
        } catch (docError) {
          log('Error processing document ${doc.id}: $docError');
        }
      }

      return articles;
    } catch (e) {
      log('Error fetching sponsored articles: $e');
      throw Exception('Failed to load sponsored articles: $e');
    }
  }
  
  String _createExcerpt(String? content) {
    if (content == null) return '';
    return content.length > 150 ? '${content.substring(0, 150)}...' : content;
  }
}