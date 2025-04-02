import 'package:flutter/material.dart';
import 'package:neusenews/features/news/screens/category_screen.dart';

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
    return CategoryScreen(
      category: 'Public Notices',
      url: 'https://www.neusenews.com/index/category/Public+Notices?format=rss',
      categoryColor: const Color(
        0xFFd2982a,
      ), // Using your app's theme color instead of plain yellow
      showAppBar: showAppBar,
      showBottomNav: showBottomNav,
      // Removed the undefined parameter
      // Removed the undefined parameter
    );
  }
}
