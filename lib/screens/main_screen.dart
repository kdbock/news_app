import 'package:flutter/material.dart';
import 'package:neusenews/screens/dashboard_screen.dart';
import 'package:neusenews/screens/local_news_screen.dart';
import 'package:neusenews/screens/weather_screen.dart';
import 'package:neusenews/screens/calendar_screen.dart';
import 'package:neusenews/screens/sports_screen.dart';
import 'package:neusenews/screens/politics_screen.dart';
import 'package:neusenews/screens/obituaries_screen.dart';
import 'package:neusenews/screens/public_notices_screen.dart';
import 'package:neusenews/screens/columns_screen.dart';
import 'package:neusenews/screens/classifieds_screen.dart';
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
    const LocalNewsScreen(showAppBar: false),
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
    switch (_currentCategory) {
      case 'localnews':
        return const LocalNewsScreen(showAppBar: false);
      case 'sports':
        return const SportsScreen(showAppBar: false);
      case 'politics':
        return const PoliticsScreen(showAppBar: false);
      case 'columns':
        return const ColumnsScreen(showAppBar: false);
      case 'classifieds':
        return const ClassifiedsScreen(showAppBar: false);
      case 'obituaries':
        return const ObituariesScreen(showAppBar: false);
      case 'publicnotices':
        return const PublicNoticesScreen(showAppBar: false);
      default:
        return const LocalNewsScreen(showAppBar: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neuse News'), centerTitle: true),
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
