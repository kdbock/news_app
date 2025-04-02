import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class PoliticsScreen extends StatelessWidget {
  final bool showAppBar;

  const PoliticsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Politics',
      url: 'https://www.ncpoliticalnews.com/news?format=rss',
      categoryColor: Colors.red,
      showAppBar: showAppBar,
      showBottomNav: true,
    );
  }
}
