import 'package:flutter/material.dart';
import 'package:neusenews/constants/app_colors.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFFd2982a);
  static const Color secondary = Color(0xFF2d2c31);
  static const Color background = Color(0xFFf9f9f9);
  static const Color cardBackground = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF1E88E5);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2d2c31);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textWhite = Colors.white;
  
  // Category colors
  static const Color sportsColor = Color(0xFF4CAF50);
  static const Color politicsColor = Color(0xFFE53935);
  static const Color weatherColor = Color(0xFF1E88E5);
  static const Color obituariesColor = Color(0xFF7E57C2);
  static const Color columnsColor = Color(0xFF00ACC1);
  static const Color classifiedsColor = Color(0xFFFF9800);
  static const Color noticesColor = Color(0xFF5C6BC0);
  
  // Text styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: textPrimary,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    color: textPrimary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primary,
  );
  
  // Card styling
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Generate ThemeData for the app
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: secondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: const TextTheme(
        displayLarge: headline1,
        displayMedium: headline2,
        displaySmall: headline3,
        bodyLarge: bodyText1,
        bodyMedium: bodyText2,
        labelLarge: button,
        bodySmall: caption,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 24,
      ),
    );
  }

  // Dark theme - only basic implementation
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}