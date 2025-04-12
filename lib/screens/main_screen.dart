import 'package:flutter/material.dart';
import 'package:neusenews/screens/dashboard_screen.dart';

import 'package:neusenews/features/weather/screens/weather_screen.dart';
import 'package:neusenews/features/events/screens/calendar_screen.dart';
import 'package:neusenews/features/news/screens/news_screen.dart';

import 'package:neusenews/widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  final String? initialScreen;

  const MainScreen({super.key, this.initialScreen});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _currentCategory;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const WeatherScreen(showAppBar: false),
    const CalendarScreen(showAppBar: false),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialScreen != null) {
      _initializeWithScreen(widget.initialScreen!);
    }
  }

  void _initializeWithScreen(String screenName) {
    switch (screenName.toLowerCase()) {
      case 'dashboard':
        setState(() {
          _selectedIndex = 0;
          _currentCategory = null;
        });
        break;
      case 'localnews':
        setState(() {
          _selectedIndex = 1;
          _currentCategory = 'localnews';
        });
        break;
      case 'sports':
        setState(() {
          _selectedIndex = 1;
          _currentCategory = 'sports';
        });
        break;
      case 'politics':
        setState(() {
          _selectedIndex = 1;
          _currentCategory = 'politics';
        });
        break;
      case 'columns':
        setState(() {
          _selectedIndex = 1;
          _currentCategory = 'columns';
        });
        break;
      case 'classifieds':
        setState(() {
          _selectedIndex = 1;
          _currentCategory = 'classifieds';
        });
        break;
      case 'obituaries':
        setState(() {
          _selectedIndex = 1;
          _currentCategory = 'obituaries';
        });
        break;
      case 'publicnotices':
        setState(() {
          _selectedIndex = 1;
          _currentCategory = 'publicnotices';
        });
        break;
      case 'weather':
        setState(() {
          _selectedIndex = 2;
          _currentCategory = null;
        });
        break;
      case 'calendar':
        setState(() {
          _selectedIndex = 3;
          _currentCategory = null;
        });
        break;
      default:
        setState(() {
          _selectedIndex = 0;
          _currentCategory = null;
        });
    }
  }

  Widget _buildNewsContent() {
    // Use the NewsScreen with the current category as an argument
    return NewsScreen(
      showAppBar: false,
      showBottomNav: false,
      initialTab: _currentCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuse News'),
        centerTitle: true,
        backgroundColor: const Color(0xFFd2982a),
      ),
      drawer: const AppDrawer(),
      body:
          _selectedIndex == 1 ? _buildNewsContent() : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _currentCategory = null; // Reset category when switching tabs
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFd2982a),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
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
    );
  }
}
