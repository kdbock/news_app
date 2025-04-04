import 'package:flutter/material.dart';
import 'package:neusenews/features/news/screens/category_screen.dart';

class MattersOfRecordScreen extends StatelessWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const MattersOfRecordScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Matters of Record',
      url:
          'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
      categoryColor: const Color(0xFFd2982a),
      showAppBar: showAppBar,
      showBottomNav: showBottomNav,
      navBarBackgroundColor: const Color(0xFFd2982a), // Match your theme
      navBarSelectedItemColor: Colors.white,
      navBarUnselectedItemColor: Colors.white70,
      useBackButton: true,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Add search functionality
          },
        ),
      ],
    );
  }
}