import 'package:flutter/material.dart';

class AdResponsiveUtils {
  static double getAdCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width > 1200) {
      return width * 0.25; // 4 cards per row on large screens
    } else if (width > 800) {
      return width * 0.4; // 2 cards per row on medium screens
    } else {
      return width - 32; // Full width (minus padding) on small screens
    }
  }
  
  static Widget buildResponsiveAdOptions(
    BuildContext context, 
    List<Widget> adOptionCards
  ) {
    final width = MediaQuery.of(context).size.width;
    
    if (width > 800) {
      // For larger screens - grid layout
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width > 1200 ? 3 : 2,
          childAspectRatio: 1.2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: adOptionCards.length,
        itemBuilder: (context, index) => adOptionCards[index],
      );
    } else {
      // For mobile - column layout
      return Column(
        children: adOptionCards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: card,
          );
        }).toList(),
      );
    }
  }
}