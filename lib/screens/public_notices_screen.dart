import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class PublicNoticesScreen extends StatelessWidget {
  final bool showAppBar;

  const PublicNoticesScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Public Notices',
      url: 'https://www.neusenews.com/index/category/Public+Notices?format=rss',
      categoryColor: Colors.indigo,
      showAppBar: showAppBar,
      showBottomNav: true,
      // Remove articlesBuilder parameter entirely
    );
  }
}
