import 'package:flutter/material.dart';
import 'package:news_app/screens/category_screen.dart';

class PublicNoticesScreen extends StatelessWidget {
  const PublicNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryScreen(
      category: 'Public Notices',
      url: 'https://www.neusenews.com/public-notices?format=rss',
      categoryColor: Colors.teal,
    );
  }
}
