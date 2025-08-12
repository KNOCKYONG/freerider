import 'package:flutter/material.dart';

/// FREERIDER 앱 스페이싱 시스템 (8dp 그리드 기반)
class AppSpacing {
  AppSpacing._();
  
  // Base unit (8dp grid system)
  static const double unit = 8.0;
  
  // Spacing values
  static const double xxs = 2.0;   // 0.25 * unit
  static const double xs = 4.0;    // 0.5 * unit
  static const double sm = 8.0;    // 1 * unit
  static const double md = 16.0;   // 2 * unit
  static const double lg = 24.0;   // 3 * unit
  static const double xl = 32.0;   // 4 * unit
  static const double xxl = 40.0;  // 5 * unit
  static const double xxxl = 48.0; // 6 * unit
  static const double huge = 56.0; // 7 * unit
  static const double giant = 64.0; // 8 * unit
  
  // Component specific spacing
  static const double cardPadding = md;
  static const double screenPadding = md;
  static const double sectionSpacing = lg;
  static const double itemSpacing = sm;
  static const double iconTextSpacing = xs;
  
  // Touch target sizes (최소 48x48dp)
  static const double touchTargetMin = 48.0;
  static const double touchTargetSmall = 40.0;
  static const double touchTargetLarge = 56.0;
  
  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0;
  
  // Component specific radius
  static const double cardRadius = radiusMd;
  static const double buttonRadius = radiusSm;
  static const double bottomSheetRadius = radiusXl;
  static const double dialogRadius = radiusLg;
  
  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;
  
  // Button heights
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;
  
  // App bar height
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 56.0;
  
  // Edge Insets helpers
  static const EdgeInsets paddingAll = EdgeInsets.all(md);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);
  
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);
  
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);
  
  // Screen padding
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(screenPadding);
  
  // Card padding
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);
  
  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  
  // Shadows
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
  
  // Elevation shadows (Material Design)
  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 4,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevation8 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 8),
    ),
  ];
}