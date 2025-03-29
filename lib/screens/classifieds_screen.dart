import 'package:flutter/material.dart';
import 'package:neusenews/screens/category_screen.dart';

class ClassifiedsScreen extends StatelessWidget {
  const ClassifiedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(
      category: 'Classifieds',
      url: 'https://www.neusenews.com/classifieds?format=rss',
      categoryColor: Colors.orange,
    );
  }
}
