import 'package:flutter/material.dart';
import 'package:news_app/screens/category_screen.dart';

class PoliticsScreen extends StatelessWidget {
  const PoliticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(
      category: 'NC Politics',
      url: 'https://www.ncpoliticalnews.com/news?format=rss',
      categoryColor: Colors.red,
    );
  }
}
