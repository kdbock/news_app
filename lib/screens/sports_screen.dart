import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class SportsScreen extends StatelessWidget {
  final bool showAppBar;

  const SportsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Sports',
      url: 'https://www.neusenewssports.com/news-1?format=rss',
      categoryColor: Colors.yellow,
      showAppBar: showAppBar,
      showBottomNav: true,
    );
  }
}
