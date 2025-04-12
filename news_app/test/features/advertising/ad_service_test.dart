// filepath: /Users/kristybock/news_app/lib/screens/firebase_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/widgets/in_feed_ad_banner.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card.dart';

class FirebaseDashboardScreen extends StatefulWidget {
  const FirebaseDashboardScreen({super.key});

  @override
  _FirebaseDashboardScreenState createState() => _FirebaseDashboardScreenState();
}

class _FirebaseDashboardScreenState extends State<FirebaseDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Article> _articles = [];
  List<Ad> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch articles
      final articlesSnapshot = await _firestore.collection('articles').get();
      final adsSnapshot = await _firestore.collection('ads').get();

      setState(() {
        _articles = articlesSnapshot.docs
            .map((doc) => Article.fromJson(doc.data()))
            .toList();
        _ads = adsSnapshot.docs.map((doc) => Ad.fromJson(doc.data())).toList();
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display ads
            InFeedAdBanner(adType: AdType.bannerAd), // Example ad type

            // Display articles
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
                return NewsCard(
                  article: article,
                  onReadMore: () {
                    // Navigate to article detail
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}