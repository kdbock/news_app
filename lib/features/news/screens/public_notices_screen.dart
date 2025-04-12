import 'package:flutter/material.dart';
import 'package:neusenews/features/news/screens/category_screen.dart';
import 'package:neusenews/widgets/bottom_nav_bar.dart';

class PublicNoticesScreen extends StatelessWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const PublicNoticesScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Public Notices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to the search screen
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
        backgroundColor: const Color(0xFFd2982a), // Gold header
        foregroundColor: Colors.white,
      ),
      body: CategoryScreen(
        category: 'Public Notices',
        url:
            'https://www.neusenews.com/index/category/Public+Notices?format=rss',
        categoryColor: const Color(0xFFd2982a), // Gold for category
        showAppBar: false,
        showBottomNav: false,
      ),
      bottomNavigationBar:
          showBottomNav
              ? AppBottomNavBar(
                currentIndex: 1, // Index for "News" tab
                onTap: (index) {
                  // Handle navigation between tabs
                  switch (index) {
                    case 0:
                      Navigator.pushNamed(context, '/dashboard');
                      break;
                    case 1:
                      Navigator.pushNamed(context, '/news');
                      break;
                    case 2:
                      Navigator.pushNamed(context, '/weather');
                      break;
                    case 3:
                      Navigator.pushNamed(context, '/calendar');
                      break;
                  }
                },
              )
              : null,
    );
  }
}
