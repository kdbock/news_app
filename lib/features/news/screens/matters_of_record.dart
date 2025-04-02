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
    );
  }
}
