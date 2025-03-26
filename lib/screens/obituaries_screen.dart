import 'package:flutter/material.dart';
import 'package:news_app/screens/category_screen.dart';

class ObituariesScreen extends StatelessWidget {
  const ObituariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(
      category: 'Obituaries',
      url: 'https://www.neusenews.com/obituaries-1?format=rss',
      categoryColor: Colors.purple,
    );
  }
}
