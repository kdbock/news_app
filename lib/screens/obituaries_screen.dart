import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class ObituariesScreen extends StatelessWidget {
  final bool showAppBar;

  const ObituariesScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Obituaries',
      url: 'https://www.neusenews.com/index/category/Obituaries?format=rss',
      categoryColor: Colors.purple,
      showAppBar: showAppBar,
      showBottomNav: true,
    );
  }
}
