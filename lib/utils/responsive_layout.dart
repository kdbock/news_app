import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class ResponsiveLayout {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 900) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  static bool isMobile(BuildContext context) => 
      getDeviceType(context) == DeviceType.mobile;
      
  static bool isTablet(BuildContext context) => 
      getDeviceType(context) == DeviceType.tablet;
      
  static bool isDesktop(BuildContext context) => 
      getDeviceType(context) == DeviceType.desktop;
  
  // Get appropriate image height based on device
  static double getImageHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 200;
      case DeviceType.tablet:
        return 240;
      case DeviceType.desktop:
        return 280;
    }
  }
  
  // Get appropriate grid column count based on device
  static int getGridColumnCount(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }
  
  // Get appropriate font size based on device
  static double getHeadlineFontSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 18;
      case DeviceType.tablet:
        return 22;
      case DeviceType.desktop:
        return 24;
    }
  }
  
  // Get appropriate card padding based on device
  static EdgeInsets getCardPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
  
  // Widget that adapts based on screen size
  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}