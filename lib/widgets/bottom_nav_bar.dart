import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFd2982a), // Gold for active
          unselectedItemColor: const Color(
            0xFF2d2c31,
          ), // Dark gray for inactive
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
          ],
        ),
      ),
    );
  }
}
