import 'package:flutter/material.dart';

class CategoryNavigationBar extends StatefulWidget {
  final List<CategoryItem> categories;
  final Function(String) onCategorySelected;
  final String initialCategory;

  const CategoryNavigationBar({
    super.key,
    required this.categories,
    required this.onCategorySelected,
    required this.initialCategory,
  });

  @override
  State<CategoryNavigationBar> createState() => _CategoryNavigationBarState();
}

class _CategoryNavigationBarState extends State<CategoryNavigationBar> {
  late String _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40, // Reduced height for a narrower bar
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFd2982a), // Theme gold color
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Row(
          children:
              widget.categories.map((category) {
                final isSelected = _selectedCategory == category.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.id;
                    });
                    widget.onCategorySelected(category.id);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 6.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFFd2982a)
                                  : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Text(
                      category.label,
                      style: TextStyle(
                        color: const Color(0xFF2d2c31), // Theme dark gray
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String id;
  final String label;
  final String route;

  CategoryItem({required this.id, required this.label, required this.route});
}
