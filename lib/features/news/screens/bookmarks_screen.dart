import 'package:flutter/material.dart';
import 'package:neusenews/repositories/bookmarks_repository.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:provider/provider.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh bookmarks when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookmarksRepository>(context, listen: false).loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
      ),
      drawer: const AppDrawer(),
      body: Consumer<BookmarksRepository>(
        builder: (context, bookmarksRepo, child) {
          if (bookmarksRepo.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFd2982a)),
            );
          }

          final bookmarks = bookmarksRepo.bookmarkedArticles;
          
          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved articles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Articles you save will appear here',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/news');
                    },
                    icon: const Icon(Icons.newspaper),
                    label: const Text('BROWSE NEWS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd2982a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final article = bookmarks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: NewsCard(
                  article: article,
                  onReadMore: () {
                    Navigator.pushNamed(
                      context,
                      '/article',
                      arguments: article,
                    );
                  },
                  showBookmarkButton: true,
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // News tab is active
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/home');
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
      ),
    );
  }
}