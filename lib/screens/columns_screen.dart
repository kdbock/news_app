import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class ColumnsScreen extends StatelessWidget {
  const ColumnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(
      category: 'Columns',
      url: 'https://www.neusenews.com/columns?format=rss',
      categoryColor: Colors.amber,
    );
  }
}
