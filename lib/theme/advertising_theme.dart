import 'package:flutter/material.dart';

/// Theme extension for advertising-specific styling
///
/// This class provides consistent theming for all advertising screens
/// and widgets throughout the app, while allowing for easy customization
/// if needed in the future.
class AdvertisingTheme extends ThemeExtension<AdvertisingTheme> {
  final Color primaryColor;
  final Color cardBackgroundColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final BorderRadius cardBorderRadius;
  final EdgeInsets defaultPadding;
  final double headingFontSize;
  final double subheadingFontSize;
  
  const AdvertisingTheme({
    required this.primaryColor,
    required this.cardBackgroundColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.cardBorderRadius,
    required this.defaultPadding,
    required this.headingFontSize,
    required this.subheadingFontSize,
  });

  /// Default advertising theme used throughout the app
  static AdvertisingTheme of(BuildContext context) {
    return Theme.of(context).extension<AdvertisingTheme>() ?? 
      const AdvertisingTheme(
        primaryColor: Color(0xFFd2982a), // Gold color used throughout the app
        cardBackgroundColor: Colors.white,
        textPrimaryColor: Color(0xFF2d2c31),
        textSecondaryColor: Colors.grey,
        cardBorderRadius: BorderRadius.all(Radius.circular(12)),
        defaultPadding: EdgeInsets.all(16.0),
        headingFontSize: 22.0,
        subheadingFontSize: 18.0,
      );
  }

  /// Dark theme variant for advertising
  static AdvertisingTheme darkTheme() {
    return const AdvertisingTheme(
      primaryColor: Color(0xFFe8b545), // Slightly lighter gold for dark theme
      cardBackgroundColor: Color(0xFF2d2c31), 
      textPrimaryColor: Colors.white,
      textSecondaryColor: Colors.grey,
      cardBorderRadius: BorderRadius.all(Radius.circular(12)),
      defaultPadding: EdgeInsets.all(16.0),
      headingFontSize: 22.0,
      subheadingFontSize: 18.0,
    );
  }
  
  @override
  ThemeExtension<AdvertisingTheme> copyWith({
    Color? primaryColor,
    Color? cardBackgroundColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    BorderRadius? cardBorderRadius,
    EdgeInsets? defaultPadding,
    double? headingFontSize,
    double? subheadingFontSize,
  }) {
    return AdvertisingTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      defaultPadding: defaultPadding ?? this.defaultPadding,
      headingFontSize: headingFontSize ?? this.headingFontSize,
      subheadingFontSize: subheadingFontSize ?? this.subheadingFontSize,
    );
  }
  
  @override
  ThemeExtension<AdvertisingTheme> lerp(
    covariant ThemeExtension<AdvertisingTheme>? other, 
    double t
  ) {
    if (other is! AdvertisingTheme) {
      return this;
    }
    
    return AdvertisingTheme(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      cardBackgroundColor: Color.lerp(cardBackgroundColor, other.cardBackgroundColor, t)!,
      textPrimaryColor: Color.lerp(textPrimaryColor, other.textPrimaryColor, t)!,
      textSecondaryColor: Color.lerp(textSecondaryColor, other.textSecondaryColor, t)!,
      cardBorderRadius: BorderRadius.lerp(cardBorderRadius, other.cardBorderRadius, t)!,
      defaultPadding: EdgeInsets.lerp(defaultPadding, other.defaultPadding, t)!,
      headingFontSize: lerpDouble(headingFontSize, other.headingFontSize, t)!,
      subheadingFontSize: lerpDouble(subheadingFontSize, other.subheadingFontSize, t)!,
    );
  }

  // Helper function for lerping double values
  static double? lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}