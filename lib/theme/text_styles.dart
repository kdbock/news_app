import 'package:flutter/material.dart';
import 'package:neusenews/constants/app_colors.dart';

class TextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    letterSpacing: -1.0,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.5,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle headline5 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle headline6 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF757575),
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: Color(0xFF757575),
    letterSpacing: 0.5,
  );

  // Custom styles for the app
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF757575),
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
  );
}