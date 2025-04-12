import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neusenews/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String THEME_MODE_KEY = 'theme_mode';
  static const String TEXT_SIZE_KEY = 'text_size';
  
  // Theme mode
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  
  // Text size scale factor (1.0 is normal size)
  double _textScaleFactor = 1.0;
  double get textScaleFactor => _textScaleFactor;
  
  // Return the current theme based on mode
  ThemeData get theme {
    return _themeMode == ThemeMode.dark 
      ? AppTheme.darkTheme 
      : AppTheme.lightTheme;
  }
  
  ThemeProvider() {
    _loadPreferences();
  }
  
  // Load theme preferences from shared preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme mode
    final themeModeIndex = prefs.getInt(THEME_MODE_KEY) ?? 1;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    // Text size
    _textScaleFactor = prefs.getDouble(TEXT_SIZE_KEY) ?? 1.0;
    
    // Notify listeners
    notifyListeners();
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(THEME_MODE_KEY, mode.index);
  }
  
  // Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    if (_textScaleFactor == factor) return;
    
    _textScaleFactor = factor;
    notifyListeners();
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(TEXT_SIZE_KEY, factor);
  }
  
  // Toggle between light and dark mode
  Future<void> toggleThemeMode() async {
    final newMode = _themeMode == ThemeMode.light 
      ? ThemeMode.dark 
      : ThemeMode.light;
      
    await setThemeMode(newMode);
  }
  
  // Increase text size
  Future<void> increaseTextSize() async {
    if (_textScaleFactor >= 1.5) return; // Maximum size
    await setTextScaleFactor(_textScaleFactor + 0.1);
  }
  
  // Decrease text size
  Future<void> decreaseTextSize() async {
    if (_textScaleFactor <= 0.8) return; // Minimum size
    await setTextScaleFactor(_textScaleFactor - 0.1);
  }
  
  // Reset text size to default
  Future<void> resetTextSize() async {
    await setTextScaleFactor(1.0);
  }
}