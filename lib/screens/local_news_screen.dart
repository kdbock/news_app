import 'package:flutter/material.dart';
import 'package:news_app/screens/category_screen.dart';

class LocalNewsScreen extends StatelessWidget {
  const LocalNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(
      category: 'Local News',
      url: 'https://www.neusenews.com/index?format=rss',
      categoryColor: Colors.blue,
    );
  }
}
