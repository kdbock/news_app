import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'dart:developer';

class SponsoredArticlesScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const SponsoredArticlesScreen({
    super.key, 
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  @override
  State<SponsoredArticlesScreen> createState() => _SponsoredArticlesScreenState();
}

class _SponsoredArticlesScreenState extends State<SponsoredArticlesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Article> _sponsoredArticles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSponsoredArticles();
  }

  Future<void> _loadSponsoredArticles() async {
    try {
      setState(() => _isLoading = true);
      
      log('Fetching published sponsored articles...');
      
      final snapshot = await _firestore
          .collection('sponsored_articles')
          .where('status', isEqualTo: 'published')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt', descending: true)
          .limit(20)
          .get();

      log('Found ${snapshot.docs.length} published sponsored articles');
      
      final List<Article> articles = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Handle potential null publishedAt date
          DateTime publishDate;
          try {
            publishDate = data['publishedAt']?.toDate() ?? DateTime.now();
          } catch (dateError) {
            log('Error parsing publishedAt date: $dateError, using current date instead');
            publishDate = DateTime.now();
          }
          
          final article = Article(
            id: doc.id,
            title: data['title'] ?? 'Sponsored Article',
            excerpt: data['content'] != null && data['content'].toString().length > 150
                ? '${data['content'].toString().substring(0, 150)}...'
                : data['content']?.toString() ?? '',
            content: data['content']?.toString() ?? '',
            imageUrl: data['headerImageUrl'] ?? '',
            publishDate: publishDate,
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
      
      if (mounted) {
        setState(() {
          _sponsoredArticles = articles;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      log('Error fetching sponsored articles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load sponsored articles';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? 
        AppBar(
          title: const Text('Sponsored Content'),
          backgroundColor: const Color(0xFFd2982a),
          elevation: 1,
        ) : null,
      drawer: widget.showAppBar ? const AppDrawer() : null,
      body: RefreshIndicator(
        onRefresh: _loadSponsoredArticles,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFd2982a)))
          : _sponsoredArticles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_errorMessage ?? 'No sponsored articles available'),
                      if (_errorMessage != null)
                        ElevatedButton(
                          onPressed: _loadSponsoredArticles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd2982a),
                          ),
                          child: const Text('Try Again'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _sponsoredArticles.length,
                  itemBuilder: (context, index) {
                    return NewsCard(
                      article: _sponsoredArticles[index],
                      onReadMore: () {
                        Navigator.pushNamed(
                          context,
                          '/article',
                          arguments: _sponsoredArticles[index],
                        );
                      },
                      sourceTag: 'Sponsored',
                    );
                  },
                ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 0, // Home tab is active when viewing sponsored articles
              onTap: (index) {
                switch (index) {
                  case 0: // Home
                    Navigator.pushReplacementNamed(context, '/dashboard');
                    break;
                  case 1: // News
                    Navigator.pushReplacementNamed(context, '/news');
                    break;
                  case 2: // Weather
                    Navigator.pushReplacementNamed(context, '/weather');
                    break;
                  case 3: // Calendar
                    Navigator.pushReplacementNamed(context, '/calendar');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
                BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
              ],
            )
          : null,
    );
  }
}