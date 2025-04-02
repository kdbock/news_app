import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class ColumnsScreen extends StatelessWidget {
  final bool showAppBar;

  const ColumnsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return CategoryScreen(
      category: 'Columns',
      url: 'https://www.neusenews.com/index/category/Columns?format=rss',
      categoryColor: Colors.orange,
      showAppBar: showAppBar,
    );
  }
}
