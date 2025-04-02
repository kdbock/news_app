import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class ClassifiedsScreen extends StatelessWidget {
  final bool showAppBar;

  const ClassifiedsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Classifieds',
      url: 'https://www.neusenews.com/index/category/Classifieds?format=rss',
      categoryColor: Colors.brown,
      showAppBar: showAppBar,
    showBottomNav: true,
    // Remove articlesBuilder parameter entirely
  );
}
}