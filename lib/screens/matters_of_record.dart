import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class MattersOfRecordScreen extends StatelessWidget {
  final bool showAppBar;

  const MattersOfRecordScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Matters of Record',
      url:
          'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
      categoryColor: Colors.orange,
      showAppBar: showAppBar,
      showBottomNav: true,
    );
  }
}
