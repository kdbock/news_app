import 'package:neusenews/features/news/screens/base_category_screen.dart';

class CategoryScreen extends BaseCategoryScreen {
  const CategoryScreen({
    super.key,
    required super.category,
    required super.url,
    required super.categoryColor,
    super.showAppBar = true,
    super.showBottomNav = true,
  });
}
