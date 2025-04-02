import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class LocalNewsScreen extends StatelessWidget {
  final bool showAppBar;

  const LocalNewsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Local News',
      url: 'https://www.neusenews.com/index/category/Local+News?format=rss',
      categoryColor: Colors.blue,
      showAppBar: showAppBar,
      showBottomNav: true,
    );
  }
}
