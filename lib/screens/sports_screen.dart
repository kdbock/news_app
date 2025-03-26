import 'package:flutter/material.dart';
import 'package:news_app/screens/category_screen.dart';

class SportsScreen extends StatelessWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(
      category: 'Sports',
      url: 'https://www.neusenewssports.com/news-1?format=rss',
      categoryColor: Colors.green,
    );
  }
}
