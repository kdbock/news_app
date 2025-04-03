import 'package:flutter/material.dart';

/// Centralized layout constants to ensure consistency across components
class LayoutConstants {
  // Card dimensions - used by BOTH article cards and ad banners
  static const double cardWidth = 270.0;
  static const double cardHeight = 220.0;
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 12.0,
  );
  static const double cardBorderRadius = 12.0;
  static const double cardElevation = 3.0;

  // Shared text styles
  static const TextStyle headlineStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14.0,
    overflow: TextOverflow.ellipsis,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 12.0,
    overflow: TextOverflow.ellipsis,
  );

  // Sponsor badge styling
  static const TextStyle sponsorLabelStyle = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
  );
}
