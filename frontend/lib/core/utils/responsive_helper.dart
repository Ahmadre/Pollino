import 'package:flutter/material.dart';

/// Responsive Helper Class basierend auf UX Best Practices und Goldenen Schnitt
class ResponsiveHelper {
  // Breakpoints basierend auf Material Design 3 und UX Best Practices
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1920;

  // Container Breiten basierend auf Goldenen Schnitt (1.618)
  static const double maxContentWidth = 1920; // Desktop Container
  static const double maxReadingWidth = 1200; // Optimale Lesbreite
  static const double maxFormWidth = 600; // Forms und Input-Bereiche
  static const double maxCardWidth = 400; // Poll Cards

  // Goldener Schnitt Verhältnisse
  static const double goldenRatio = 1.618;
  static const double inverseGoldenRatio = 0.618;

  /// Erkennt den aktuellen Device-Typ
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Gibt zurück ob aktuelles Device mobile ist
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Gibt zurück ob aktuelles Device tablet ist
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Gibt zurück ob aktuelles Device desktop ist
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Berechnet responsive Spaltenanzahl für Grids
  static int getGridColumns(BuildContext context) {
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

  /// Berechnet responsive Padding basierend auf Screen-Größe
  static EdgeInsets getScreenPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(24.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(32.0);
    }
  }

  /// Berechnet responsive Chart-Höhe basierend auf Goldenen Schnitt
  static double getChartHeight(BuildContext context, {bool isInCard = false}) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return (width * 0.6).clamp(200.0, 300.0);
      case DeviceType.tablet:
        return isInCard ? 220.0 : (width * 0.4).clamp(250.0, 350.0);
      case DeviceType.desktop:
        return isInCard ? 250.0 : 300.0; // Kleinere Höhe für Cards
    }
  }

  /// Berechnet optimale Container-Breite
  static double getContainerWidth(BuildContext context, {double? maxWidth}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetWidth = maxWidth ?? maxContentWidth;

    return screenWidth > targetWidth ? targetWidth : screenWidth - getScreenPadding(context).horizontal;
  }

  /// Responsive Text Scaling
  static double getTextScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
    }
  }
}

/// Device Type Enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Extension für responsive Werte
extension ResponsiveValue<T> on T {
  T responsive(BuildContext context, {T? tablet, T? desktop}) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return this;
      case DeviceType.tablet:
        return tablet ?? this;
      case DeviceType.desktop:
        return desktop ?? tablet ?? this;
    }
  }
}
