# Free Rider Flutter UI/UX Implementation Guide
## Complete Flutter Development Specifications

### Version 1.0 | Flutter 3.x | 2024

---

## Table of Contents
1. [Project Setup](#1-project-setup)
2. [Design System](#2-design-system)
3. [Core Widgets](#3-core-widgets)
4. [Screen Implementations](#4-screen-implementations)
5. [Animations & Interactions](#5-animations-interactions)
6. [State Management](#6-state-management)
7. [Navigation](#7-navigation)
8. [Native Features](#8-native-features)
9. [Performance Optimization](#9-performance-optimization)
10. [Testing Guide](#10-testing-guide)

---

## 1. Project Setup

### 1.1 Project Structure

```bash
free_rider/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_spacing.dart
│   │   │   └── app_constants.dart
│   │   ├── themes/
│   │   │   ├── app_theme.dart
│   │   │   └── dark_theme.dart
│   │   ├── utils/
│   │   │   ├── responsive.dart
│   │   │   ├── validators.dart
│   │   │   └── formatters.dart
│   │   └── services/
│   │       ├── native_service.dart
│   │       ├── api_service.dart
│   │       └── storage_service.dart
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── providers/
│   ├── presentation/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── animations/
│   └── routes/
│       └── app_router.dart
├── assets/
│   ├── images/
│   ├── fonts/
│   ├── animations/
│   └── icons/
└── test/
```

### 1.2 Dependencies

```yaml
name: free_rider
description: 매일 무료로, 당당하게 - 대한민국 교통비 제로 플랫폼
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
    
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^12.0.0
  
  # UI/UX
  flutter_animate: ^4.3.0
  lottie: ^2.7.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flutter_slidable: ^3.0.0
  
  # Native Features
  flutter_native_splash: ^2.3.0
  flutter_local_notifications: ^16.0.0
  vibration: ^1.8.0
  flutter_nfc_kit: ^3.4.0
  
  # Storage
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  
  # API & Network
  dio: ^5.4.0
  retrofit: ^4.0.0
  pretty_dio_logger: ^1.3.0
  
  # Utils
  intl: ^0.18.0
  flutter_screenutil: ^5.9.0
  permission_handler: ^11.0.0
  url_launcher: ^6.2.0
  
  # Analytics
  firebase_core: ^2.24.0
  firebase_analytics: ^10.7.0
  firebase_crashlytics: ^3.4.0
  
  # Ads
  google_mobile_ads: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/animations/
    - assets/icons/
    
  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.otf
        - asset: assets/fonts/Pretendard-Medium.otf
          weight: 500
        - asset: assets/fonts/Pretendard-SemiBold.otf
          weight: 600
        - asset: assets/fonts/Pretendard-Bold.otf
          weight: 700
```

### 1.3 Main Entry

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: FreeRiderApp(),
    ),
  );
}

// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/themes/app_theme.dart';
import 'routes/app_router.dart';

class FreeRiderApp extends ConsumerWidget {
  const FreeRiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 Pro
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Free Rider',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
        );
      },
    );
  }
}
```

---

## 2. Design System

### 2.1 Color System

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color freeGreen = Color(0xFF00FF88);
  static const Color freeGreenDark = Color(0xFF00CC70);
  static const Color freeGreenLight = Color(0xFFE5FFEF);
  
  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color gray900 = Color(0xFF191919);
  static const Color gray700 = Color(0xFF333333);
  static const Color gray500 = Color(0xFF666666);
  static const Color gray300 = Color(0xFF999999);
  static const Color gray100 = Color(0xFFE5E5E5);
  static const Color gray50 = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  
  // Semantic Colors
  static const Color success = Color(0xFF00D67E);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF0066FF);
  
  // Dark Theme Colors
  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurface2 = Color(0xFF2C2C2E);
  
  // Gradients
  static const LinearGradient rewardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [freeGreen, info],
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
  );
  
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [freeGreen, white],
  );
}
```

### 2.2 Typography

```dart
// lib/core/constants/app_typography.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTypography {
  static const String fontFamily = 'Pretendard';
  
  // Display
  static TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.1,
  );
  
  static TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.2,
  );
  
  static TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  // Headlines
  static TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body
  static TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  
  static TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  // Caption
  static TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
  );
  
  // Button
  static TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
```

### 2.3 Spacing & Responsive

```dart
// lib/core/utils/responsive.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  static double xs = 4.w;
  static double sm = 8.w;
  static double md = 16.w;
  static double lg = 24.w;
  static double xl = 32.w;
  static double xxl = 48.w;
  static double xxxl = 64.w;
}

extension ResponsiveExtension on num {
  // Width
  double get w => ScreenUtil().setWidth(this);
  
  // Height  
  double get h => ScreenUtil().setHeight(this);
  
  // Font Size
  double get sp => ScreenUtil().setSp(this);
  
  // Radius
  double get r => ScreenUtil().radius(this);
  
  // Vertical Spacing
  SizedBox get verticalSpace => SizedBox(height: h);
  
  // Horizontal Spacing
  SizedBox get horizontalSpace => SizedBox(width: w);
}

// Padding Extensions
extension PaddingExtension on Widget {
  Widget paddingAll(double value) => Padding(
    padding: EdgeInsets.all(value.w),
    child: this,
  );
  
  Widget paddingSymmetric({double h = 0, double v = 0}) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: h.w,
      vertical: v.h,
    ),
    child: this,
  );
  
  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => Padding(
    padding: EdgeInsets.only(
      left: left.w,
      top: top.h,
      right: right.w,
      bottom: bottom.h,
    ),
    child: this,
  );
}
```

### 2.4 Theme Configuration

```dart
// lib/core/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.freeGreen,
      secondary: AppColors.freeGreenDark,
      surface: AppColors.white,
      background: AppColors.gray50,
      error: AppColors.error,
      onPrimary: AppColors.black,
      onSecondary: AppColors.white,
      onSurface: AppColors.black,
      onBackground: AppColors.black,
      onError: AppColors.white,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.gray50,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.black),
      iconTheme: const IconThemeData(color: AppColors.black),
      actionsIconTheme: const IconThemeData(color: AppColors.black),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.freeGreen,
      unselectedItemColor: AppColors.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.freeGreen,
        foregroundColor: AppColors.black,
        minimumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        textStyle: AppTypography.button,
        elevation: 0,
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.freeGreen,
        textStyle: AppTypography.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.gray100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.gray100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.freeGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTypography.body.copyWith(color: AppColors.gray500),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.gray100,
      thickness: 1,
    ),
  );
  
  static ThemeData get dark => light.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.freeGreen,
      secondary: AppColors.freeGreenDark,
      surface: AppColors.darkSurface,
      background: AppColors.darkBg,
      error: AppColors.error,
      onPrimary: AppColors.black,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
      onBackground: AppColors.white,
      onError: AppColors.white,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.white),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    
    cardTheme: CardTheme(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
    ),
  );
}
```

---

## 3. Core Widgets

### 3.1 Primary Button

```dart
// lib/presentation/widgets/buttons/primary_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool haptic;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.haptic = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
      if (widget.haptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.isEnabled && !widget.isLoading;
    final backgroundColor = widget.backgroundColor ?? 
      (isEnabled ? AppColors.freeGreen : AppColors.gray300);
    final textColor = widget.textColor ?? 
      (isEnabled ? AppColors.black : AppColors.gray500);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 56.h,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: isEnabled && !_isPressed
                    ? [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 20.sp,
                              color: textColor,
                            ),
                            8.horizontalSpace,
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate(target: _isPressed ? 1 : 0)
              .shimmer(
                duration: 400.ms,
                color: AppColors.white.withOpacity(0.3),
              ),
          );
        },
      ),
    );
  }
}
```

### 3.2 Point Card

```dart
// lib/presentation/widgets/cards/point_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../buttons/primary_button.dart';

class PointCard extends StatelessWidget {
  final int currentPoints;
  final int targetPoints;
  final VoidCallback onCharge;
  final VoidCallback onEarnMore;

  const PointCard({
    super.key,
    required this.currentPoints,
    required this.targetPoints,
    required this.onCharge,
    required this.onEarnMore,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentPoints / targetPoints).clamp(0.0, 1.0);
    final remaining = targetPoints - currentPoints;
    final canCharge = currentPoints >= targetPoints;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 교통비',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              if (canCharge)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '충전 가능!',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(delay: 100.ms, duration: 200.ms),
            ],
          ),
          
          16.verticalSpace,
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.currency(currentPoints),
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    8.verticalSpace,
                    
                    // Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          height: 8.h,
                          width: (MediaQuery.of(context).size.width - 160.w) * progress,
                          decoration: BoxDecoration(
                            gradient: canCharge 
                              ? AppColors.rewardGradient
                              : LinearGradient(
                                  colors: [
                                    AppColors.freeGreen,
                                    AppColors.freeGreenDark,
                                  ],
                                ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                    
                    8.verticalSpace,
                    
                    Text(
                      canCharge
                          ? '축하해요! 충전할 수 있어요 🎉'
                          : '${Formatters.currency(remaining)}만 더 모으면 돼요!',
                      style: AppTypography.bodySmall.copyWith(
                        color: canCharge ? AppColors.success : AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
              
              20.horizontalSpace,
              
              // Circular Progress
              SizedBox(
                width: 80.w,
                height: 80.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppColors.gray100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        canCharge ? AppColors.success : AppColors.freeGreen,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) {
                if (progress >= 0.9) controller.repeat();
              })
              .shimmer(
                duration: 2000.ms,
                color: canCharge ? AppColors.freeGreen.withOpacity(0.3) : Colors.transparent,
              ),
            ],
          ),
          
          20.verticalSpace,
          
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: canCharge ? '지금 충전하기' : '포인트 모으기',
                  onPressed: canCharge ? onCharge : onEarnMore,
                  icon: canCharge ? Icons.bolt : Icons.add_circle_outline,
                  backgroundColor: canCharge ? AppColors.freeGreen : AppColors.gray50,
                  textColor: canCharge ? AppColors.black : AppColors.gray700,
                ),
              ),
              if (canCharge) ...[
                12.horizontalSpace,
                IconButton(
                  onPressed: onEarnMore,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.gray500,
                  tooltip: '더 모으기',
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.1, end: 0);
  }
}
```

### 3.3 Transport Card Widget

```dart
// lib/presentation/widgets/cards/transport_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transport_card_model.dart';

class TransportCardWidget extends StatefulWidget {
  final List<TransportCardModel> cards;
  final Function(TransportCardModel) onCardTap;
  final VoidCallback onAddCard;

  const TransportCardWidget({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.onAddCard,
  });

  @override
  State<TransportCardWidget> createState() => _TransportCardWidgetState();
}

class _TransportCardWidgetState extends State<TransportCardWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내 교통카드',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        12.verticalSpace,
        
        SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.cards.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.cards.length) {
                return _buildAddCardButton();
              }
              return _buildCard(widget.cards[index]);
            },
          ),
        ),
        
        if (widget.cards.isNotEmpty) ...[
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.cards.length + 1,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? AppColors.freeGreen
                      : AppColors.gray300,
                ),
              ).animate(target: _currentIndex == index ? 1 : 0)
                .scale(end: 1.3, duration: 200.ms),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(TransportCardModel card) {
    return GestureDetector(
      onTap: () => widget.onCardTap(card),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: _getCardGradient(card.type),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      _getCardLogo(card.type),
                      width: 40.w,
                      height: 40.w,
                    ),
                    12.horizontalSpace,
                    Text(
                      card.nickname ?? card.type.displayName,
                      style: AppTypography.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (card.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '기본',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            const Spacer(),
            
            Text(
              '•••• •••• •••• ${card.lastFourDigits}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white.withOpacity(0.8),
                letterSpacing: 2,
              ),
            ),
            
            12.verticalSpace,
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '잔액',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      Formatters.currency(card.balance),
                      style: AppTypography.h3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '충전',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildAddCardButton() {
    return GestureDetector(
      onTap: widget.onAddCard,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.gray200,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_card,
                size: 48.sp,
                color: AppColors.gray400,
              ),
              8.verticalSpace,
              Text(
                '카드 추가하기',
                style: AppTypography.body.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.gray200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.credit_card_off,
            size: 64.sp,
            color: AppColors.gray400,
          ),
          16.verticalSpace,
          Text(
            '등록된 교통카드가 없어요',
            style: AppTypography.body.copyWith(
              color: AppColors.gray600,
            ),
          ),
          8.verticalSpace,
          Text(
            '교통카드를 등록하고\n무료 충전을 시작하세요!',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
          ),
          20.verticalSpace,
          PrimaryButton(
            text: '카드 등록하기',
            onPressed: widget.onAddCard,
            icon: Icons.add,
            width: 160.w,
            height: 44.h,
          ),
        ],
      ),
    );
  }

  LinearGradient _getCardGradient(CardType type) {
    switch (type) {
      case CardType.tmoney:
        return const LinearGradient(
          colors: [Color(0xFF0064D2), Color(0xFF00A9E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardType.cashbee:
        return const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardType.railplus:
        return const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.rewardGradient;
    }
  }

  String _getCardLogo(CardType type) {
    switch (type) {
      case CardType.tmoney:
        return 'assets/images/tmoney_logo.png';
      case CardType.cashbee:
        return 'assets/images/cashbee_logo.png';
      case CardType.railplus:
        return 'assets/images/railplus_logo.png';
      default:
        return 'assets/images/card_default.png';
    }
  }
}
```

### 3.4 Slide to Charge Button

```dart
// lib/presentation/widgets/buttons/slide_to_charge.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';

class SlideToChargeButton extends StatefulWidget {
  final VoidCallback onCharge;
  final bool isEnabled;
  final int amount;

  const SlideToChargeButton({
    super.key,
    required this.onCharge,
    required this.amount,
    this.isEnabled = true,
  });

  @override
  State<SlideToChargeButton> createState() => _SlideToChargeButtonState();
}

class _SlideToChargeButtonState extends State<SlideToChargeButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  double _maxDrag = 0;
  bool _isDragging = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resetAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      _isDragging = true;
    });
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx)
          .clamp(0.0, _maxDrag);
    });
    
    // Haptic feedback at milestones
    final progress = _dragPosition / _maxDrag;
    if (progress > 0.5 && progress < 0.52) {
      HapticFeedback.lightImpact();
    }
    if (progress > 0.9 && progress < 0.92) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.isEnabled) return;
    
    if (_dragPosition >= _maxDrag * 0.9) {
      // Success
      HapticFeedback.heavyImpact();
      widget.onCharge();
      _resetSlider();
    } else {
      // Reset
      _resetSlider();
    }
  }

  void _resetSlider() {
    _resetAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));
    
    _resetController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragPosition = 0;
          _isDragging = false;
        });
      }
    });
    
    _resetAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDrag = constraints.maxWidth - 64.w;
        final progress = _dragPosition / _maxDrag;
        
        return Container(
          height: 64.h,
          decoration: BoxDecoration(
            gradient: widget.isEnabled 
              ? LinearGradient(
                  colors: [
                    AppColors.freeGreen.withOpacity(0.1),
                    AppColors.freeGreen.withOpacity(0.2),
                  ],
                )
              : null,
            color: !widget.isEnabled ? AppColors.gray100 : null,
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: widget.isEnabled ? AppColors.freeGreen : AppColors.gray300,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Background Text
              Center(
                child: Padding(
                  padding: EdgeInsets.only(left: 64.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '밀어서 ${Formatters.currency(widget.amount)} 충전',
                        style: AppTypography.body.copyWith(
                          color: widget.isEnabled 
                            ? AppColors.gray700 
                            : AppColors.gray500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      8.horizontalSpace,
                      Icon(
                        Icons.arrow_forward,
                        color: widget.isEnabled 
                          ? AppColors.gray700 
                          : AppColors.gray500,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Progress Fill
              if (widget.isEnabled)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: _dragPosition + 64.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.rewardGradient,
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                ),
              
              // Slider Thumb
              AnimatedPositioned(
                duration: _isDragging 
                  ? Duration.zero 
                  : const Duration(milliseconds: 300),
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: widget.isEnabled 
                        ? AppColors.freeGreen 
                        : AppColors.gray500,
                      size: 24.sp,
                    ),
                  )
                  .animate(target: _isDragging ? 1 : 0)
                  .scale(end: 1.1, duration: 200.ms),
                ),
              ),
              
              // Success Indicator
              if (progress > 0.9)
                Positioned(
                  right: 20.w,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.white,
                    size: 24.sp,
                  ).animate()
                    .scale(duration: 200.ms)
                    .fadeIn(),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 4. Screen Implementations

### 4.1 Splash Screen

```dart
// lib/presentation/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize services
    await Future.delayed(const Duration(seconds: 2));
    
    // Check auth status
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    final hasSeenOnboarding = ref.read(preferencesProvider).hasSeenOnboarding;
    
    if (mounted) {
      if (isLoggedIn) {
        context.go('/home');
      } else if (!hasSeenOnboarding) {
        context.go('/onboarding');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'FR',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.freeGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward,
                          size: 24.sp,
                          color: AppColors.freeGreen,
                        ).animate(onPlay: (controller) => controller.repeat())
                          .rotate(
                            duration: 1000.ms,
                            begin: 0,
                            end: 1,
                            curve: Curves.easeInOut,
                          ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(delay: 200.ms, duration: 500.ms),
                
                40.verticalSpace,
                
                Text(
                  'Free Rider',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0),
                
                8.verticalSpace,
                
                Text(
                  '매일 무료로, 당당하게',
                  style: AppTypography.body.copyWith(
                    color: AppColors.gray700,
                  ),
                )
                .animate()
                .fadeIn(delay: 700.ms, duration: 500.ms),
                
                80.verticalSpace,
                
                // Loading Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.5),
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                      delay: Duration(milliseconds: index * 100),
                    ).fadeIn(duration: 300.ms)
                      .then()
                      .fadeOut(duration: 300.ms),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 4.2 Home Screen

```dart
// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/cards/point_card.dart';
import '../../widgets/cards/transport_card.dart';
import '../../widgets/sections/quick_actions.dart';
import '../../widgets/sections/special_mission.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final points = ref.watch(pointsProvider);
    final cards = ref.watch(transportCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        color: AppColors.freeGreen,
        onRefresh: () async {
          await ref.refresh(pointsProvider.future);
          await ref.refresh(transportCardsProvider.future);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120.h,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(
                  left: 20.w,
                  bottom: 16.h,
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    Text(
                      '${user.name}님, 오늘도 무료로 타세요!',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                  color: AppColors.black,
                ),
                16.horizontalSpace,
              ],
            ),
            
            // Content
            SliverPadding(
              padding: EdgeInsets.all(20.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Point Card
                  PointCard(
                    currentPoints: points.current,
                    targetPoints: 1550,
                    onCharge: () => context.push('/charge'),
                    onEarnMore: () => context.push('/earn'),
                  ),
                  
                  20.verticalSpace,
                  
                  // Transport Cards
                  cards.when(
                    data: (cardList) => TransportCardWidget(
                      cards: cardList,
                      onCardTap: (card) => context.push('/card/${card.id}'),
                      onAddCard: () => context.push('/add-card'),
                    ),
                    loading: () => const CardShimmer(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  
                  20.verticalSpace,
                  
                  // Quick Actions
                  QuickActions(
                    onWatchAd: () => context.push('/watch-ad'),
                    onSurvey: () => context.push('/survey'),
                    onMission: () => context.push('/mission'),
                  ),
                  
                  20.verticalSpace,
                  
                  // Special Mission
                  const SpecialMissionCard(),
                  
                  100.verticalSpace, // Bottom padding for nav bar
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '좋은 아침이에요';
    if (hour < 18) return '좋은 오후예요';
    return '좋은 저녁이에요';
  }
}
```

### 4.3 Ad Viewing Screen

```dart
// lib/presentation/screens/ad/ad_viewing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../animations/point_earn_animation.dart';

class AdViewingScreen extends ConsumerStatefulWidget {
  final int rewardAmount;
  
  const AdViewingScreen({
    super.key,
    required this.rewardAmount,
  });

  @override
  ConsumerState<AdViewingScreen> createState() => _AdViewingScreenState();
}

class _AdViewingScreenState extends ConsumerState<AdViewingScreen> {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;
  int _remainingTime = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'YOUR_AD_UNIT_ID',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded ad: ${error.message}');
          // Fallback to test ad
          _showTestAd();
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      _showTestAd();
      return;
    }

    setState(() => _isAdShowing = true);
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _handleAdComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showTestAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        _earnPoints(reward.amount.toInt());
      },
    );
  }

  void _showTestAd() {
    // Test ad for development
    setState(() => _isAdShowing = true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
        _handleAdComplete();
      }
    });
  }

  void _handleAdComplete() {
    _earnPoints(widget.rewardAmount);
  }

  void _earnPoints(int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PointEarnAnimation(
        amount: amount,
        source: '광고 시청 완료',
        onComplete: () {
          ref.read(pointsProvider.notifier).earnPoints(amount, 'ad_watch');
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.freeGreen,
              ),
              20.verticalSpace,
              Text(
                '광고 준비 중...',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
      );
    }

    if (_isAdShowing) {
      return _buildTestAdView();
    }

    return _buildPreAdScreen();
  }

  Widget _buildPreAdScreen() {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('포인트 받기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 100.sp,
                color: AppColors.freeGreen,
              ),
              
              32.verticalSpace,
              
              Text(
                '광고를 시청하고',
                style: AppTypography.h2,
              ),
              
              8.verticalSpace,
              
              Text(
                '${widget.rewardAmount}P를 받으세요!',
                style: AppTypography.h1.copyWith(
                  color: AppColors.freeGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              16.verticalSpace,
              
              Text(
                '약 30초 소요됩니다',
                style: AppTypography.body.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              
              48.verticalSpace,
              
              PrimaryButton(
                text: '광고 시청하기',
                onPressed: _showRewardedAd,
                icon: Icons.play_arrow,
              ),
              
              16.verticalSpace,
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '나중에 보기',
                  style: AppTypography.body.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestAdView() {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Fake Video Ad
          Center(
            child: Container(
              width: double.infinity,
              height: 200.h,
              color: AppColors.gray900,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.ad_units,
                      size: 48.sp,
                      color: AppColors.white,
                    ),
                    16.verticalSpace,
                    Text(
                      'Test Advertisement',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${_remainingTime}초',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    
                    // Close button (disabled during ad)
                    if (_remainingTime == 0)
                      IconButton(
                        onPressed: _handleAdComplete,
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Progress Bar
          Positioned(
            bottom: 50.h,
            left: 20.w,
            right: 20.w,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: 1 - (_remainingTime / 30),
                  backgroundColor: AppColors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.freeGreen,
                  ),
                  minHeight: 4.h,
                ),
                8.verticalSpace,
                Text(
                  '광고 시청 중... ${widget.rewardAmount}P 획득 예정',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.4 Charge Screen

```dart
// lib/presentation/screens/charge/charge_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/buttons/slide_to_charge.dart';
import '../../animations/charge_success_animation.dart';

class ChargeScreen extends ConsumerStatefulWidget {
  const ChargeScreen({super.key});

  @override
  ConsumerState<ChargeScreen> createState() => _ChargeScreenState();
}

class _ChargeScreenState extends ConsumerState<ChargeScreen> {
  bool _isCharging = false;

  Future<void> _handleCharge() async {
    setState(() => _isCharging = true);
    
    try {
      // Get selected card
      final selectedCard = ref.read(selectedCardProvider);
      if (selectedCard == null) {
        throw Exception('카드를 선택해주세요');
      }
      
      // Charge the card
      await ref.read(transportCardsProvider.notifier).chargeCard(
        selectedCard.id,
        1550,
      );
      
      // Use points
      await ref.read(pointsProvider.notifier).usePoints(1550);
      
      // Show success animation
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => ChargeSuccessAnimation(
              amount: 1550,
              onComplete: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCharging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(pointsProvider);
    final selectedCard = ref.watch(selectedCardProvider);
    final canCharge = points.current >= 1550 && selectedCard != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('교통카드 충전'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // Card Selection
              _buildCardSection(selectedCard),
              
              32.verticalSpace,
              
              // Amount Section
              _buildAmountSection(points.current),
              
              32.verticalSpace,
              
              // Info Section
              _buildInfoSection(selectedCard),
              
              const Spacer(),
              
              // Charge Button
              SlideToChargeButton(
                amount: 1550,
                onCharge: _handleCharge,
                isEnabled: canCharge && !_isCharging,
              ),
              
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(TransportCardModel? card) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: card != null ? AppColors.freeGreen : AppColors.gray200,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card,
            size: 32.sp,
            color: card != null ? AppColors.freeGreen : AppColors.gray400,
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card != null ? '충전할 카드' : '카드를 선택하세요',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                4.verticalSpace,
                Text(
                  card != null 
                    ? '${card.nickname ?? card.type.displayName} (${card.lastFourDigits})'
                    : '카드 선택하기',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (card != null) ...[
                  4.verticalSpace,
                  Text(
                    '현재 잔액: ${Formatters.currency(card.balance)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/select-card'),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(int currentPoints) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: AppColors.rewardGradient,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Text(
            '충전 금액',
            style: AppTypography.body.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
          8.verticalSpace,
          Text(
            '₩1,550',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          16.verticalSpace,
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 16.sp,
                  color: AppColors.white,
                ),
                8.horizontalSpace,
                Text(
                  '보유 포인트: ${currentPoints}P',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(TransportCardModel? card) {
    if (card == null) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20.sp,
            color: AppColors.info,
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '충전 후 예상 잔액',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.info,
                  ),
                ),
                Text(
                  Formatters.currency(card.balance + 1550),
                  style: AppTypography.body.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 6. State Management

### 6.1 Riverpod Providers

```dart
// lib/data/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    return const AuthState.initial();
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.initial();
  }
}

// lib/data/providers/points_provider.dart
@riverpod
class Points extends _$Points {
  @override
  PointsState build() {
    _loadPoints();
    return const PointsState(current: 0, total: 0, history: []);
  }

  Future<void> _loadPoints() async {
    final points = await ref.read(pointsRepositoryProvider).getPoints();
    state = points;
  }

  Future<void> earnPoints(int amount, String source) async {
    state = state.copyWith(
      current: state.current + amount,
      total: state.total + amount,
    );
    
    final entry = PointEntry(
      amount: amount,
      source: source,
      timestamp: DateTime.now(),
      type: PointType.earned,
    );
    
    state = state.copyWith(
      history: [entry, ...state.history],
    );
    
    await ref.read(pointsRepositoryProvider).addPoints(amount, source);
  }

  Future<void> usePoints(int amount) async {
    if (state.current < amount) {
      throw InsufficientPointsException();
    }
    
    state = state.copyWith(current: state.current - amount);
    
    final entry = PointEntry(
      amount: amount,
      source: '교통카드 충전',
      timestamp: DateTime.now(),
      type: PointType.used,
    );
    
    state = state.copyWith(
      history: [entry, ...state.history],
    );
    
    await ref.read(pointsRepositoryProvider).usePoints(amount);
  }
}

// lib/data/providers/cards_provider.dart
@riverpod
class TransportCards extends _$TransportCards {
  @override
  Future<List<TransportCardModel>> build() async {
    return ref.read(cardsRepositoryProvider).getCards();
  }

  Future<void> addCard(TransportCardModel card) async {
    final cards = await future;
    state = AsyncData([...cards, card]);
    await ref.read(cardsRepositoryProvider).addCard(card);
  }

  Future<void> chargeCard(String cardId, int amount) async {
    await ref.read(cardsRepositoryProvider).chargeCard(cardId, amount);
    ref.invalidateSelf();
  }

  Future<void> deleteCard(String cardId) async {
    await ref.read(cardsRepositoryProvider).deleteCard(cardId);
    ref.invalidateSelf();
  }

  Future<void> setDefaultCard(String cardId) async {
    await ref.read(cardsRepositoryProvider).setDefaultCard(cardId);
    ref.invalidateSelf();
  }
}

// Selected card provider
@riverpod
TransportCardModel? selectedCard(SelectedCardRef ref) {
  final cards = ref.watch(transportCardsProvider).value ?? [];
  return cards.firstWhere((card) => card.isDefault, orElse: () => cards.first);
}
```

### 6.2 Models

```dart
// lib/data/models/transport_card_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_card_model.freezed.dart';
part 'transport_card_model.g.dart';

@freezed
class TransportCardModel with _$TransportCardModel {
  const factory TransportCardModel({
    required String id,
    required CardType type,
    required String cardNumber,
    required String lastFourDigits,
    required int balance,
    String? nickname,
    @Default(false) bool isDefault,
    DateTime? lastChargedAt,
  }) = _TransportCardModel;

  factory TransportCardModel.fromJson(Map<String, dynamic> json) =>
      _$TransportCardModelFromJson(json);
}

enum CardType {
  tmoney('T-money'),
  cashbee('캐시비'),
  railplus('레일플러스'),
  onepass('원패스');

  final String displayName;
  const CardType(this.displayName);
}

// lib/data/models/points_model.dart
@freezed
class PointsState with _$PointsState {
  const factory PointsState({
    required int current,
    required int total,
    required List<PointEntry> history,
  }) = _PointsState;
}

@freezed
class PointEntry with _$PointEntry {
  const factory PointEntry({
    required int amount,
    required String source,
    required DateTime timestamp,
    required PointType type,
  }) = _PointEntry;
}

enum PointType { earned, used, expired }
```

---

## 7. Navigation

### 7.1 Router Configuration

```dart
// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';
      
      if (!isLoggedIn && !isLoggingIn && !isOnboarding) {
        return '/login';
      }
      
      if (isLoggedIn && (isLoggingIn || isOnboarding)) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/earn',
            builder: (context, state) => const EarnPointsScreen(),
          ),
          GoRoute(
            path: '/cards',
            builder: (context, state) => const CardsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/charge',
        pageBuilder: (context, state) => SlideTransitionPage(
          child: const ChargeScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/watch-ad',
        builder: (context, state) => AdViewingScreen(
          rewardAmount: state.extra as int? ?? 100,
        ),
      ),
      GoRoute(
        path: '/add-card',
        pageBuilder: (context, state) => BottomSheetTransitionPage(
          child: const AddCardScreen(),
          state: state,
        ),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

// lib/presentation/screens/main_shell.dart
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/earn');
        break;
      case 2:
        context.go('/cards');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.freeGreen,
          unselectedItemColor: AppColors.gray500,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: '포인트',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: '카드',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'MY',
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. Native Features

### 8.1 Platform Channels

```dart
// lib/core/services/native_service.dart
import 'package:flutter/services.dart';

class NativeService {
  static const _channel = MethodChannel('com.freerider/native');

  // NFC Card Reading
  static Future<String?> readTransportCard() async {
    try {
      final String? result = await _channel.invokeMethod('readNFCCard');
      return result;
    } on PlatformException catch (e) {
      print('Failed to read NFC: ${e.message}');
      return null;
    }
  }

  // Haptic Feedback
  static Future<void> triggerHaptic(HapticType type) async {
    try {
      await _channel.invokeMethod('haptic', {'type': type.name});
    } on PlatformException catch (e) {
      print('Haptic error: ${e.message}');
    }
  }

  // Samsung/Apple Pay Integration
  static Future<bool> chargeToMobileWallet(int amount) async {
    try {
      final bool result = await _channel.invokeMethod(
        'chargeMobileWallet',
        {'amount': amount},
      );
      return result;
    } on PlatformException catch (e) {
      print('Wallet charge error: ${e.message}');
      return false;
    }
  }

  // Biometric Authentication
  static Future<bool> authenticateBiometric() async {
    try {
      final bool result = await _channel.invokeMethod('authenticateBiometric');
      return result;
    } on PlatformException catch (e) {
      print('Biometric error: ${e.message}');
      return false;
    }
  }
}

enum HapticType { light, medium, heavy, success, warning, error }
```

### 8.2 Android Implementation

```kotlin
// android/app/src/main/kotlin/com/freerider/MainActivity.kt
package com.freerider

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.VibrationEffect
import android.os.Vibrator
import android.content.Context
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.freerider/native"
    private var nfcAdapter: NfcAdapter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readNFCCard" -> readNFCCard(result)
                    "haptic" -> {
                        val type = call.argument<String>("type")
                        triggerHaptic(type)
                        result.success(null)
                    }
                    "chargeMobileWallet" -> {
                        val amount = call.argument<Int>("amount") ?: 0
                        chargeMobileWallet(amount, result)
                    }
                    "authenticateBiometric" -> authenticateBiometric(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun triggerHaptic(type: String?) {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = when (type) {
                "light" -> VibrationEffect.createOneShot(10, 50)
                "medium" -> VibrationEffect.createOneShot(20, 100)
                "heavy" -> VibrationEffect.createOneShot(30, 200)
                "success" -> VibrationEffect.createWaveform(
                    longArrayOf(0, 50, 50, 50), -1
                )
                "warning" -> VibrationEffect.createOneShot(15, 150)
                "error" -> VibrationEffect.createWaveform(
                    longArrayOf(0, 100, 100, 100), -1
                )
                else -> VibrationEffect.createOneShot(15, 100)
            }
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(20)
        }
    }

    private fun readNFCCard(result: MethodChannel.Result) {
        // NFC implementation
        // This would interface with T-money/Cashbee SDK
        result.success("1234567890123456")
    }

    private fun chargeMobileWallet(amount: Int, result: MethodChannel.Result) {
        // Samsung Pay SDK integration
        result.success(true)
    }

    private fun authenticateBiometric(result: MethodChannel.Result) {
        val executor = ContextCompat.getMainExecutor(this)
        val biometricPrompt = BiometricPrompt(this, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    authResult: BiometricPrompt.AuthenticationResult
                ) {
                    super.onAuthenticationSucceeded(authResult)
                    result.success(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    result.success(false)
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    result.success(false)
                }
            })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Free Rider")
            .setSubtitle("지문 인증")
            .setNegativeButtonText("취소")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }
}
```

### 8.3 iOS Implementation

```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import LocalAuthentication

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.freerider/native",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "haptic":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let type = args["type"] as? String {
                    self.triggerHaptic(type: type)
                }
                result(nil)
            case "authenticateBiometric":
                self.authenticateBiometric(result: result)
            case "chargeMobileWallet":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let amount = args["amount"] as? Int {
                    self.chargeMobileWallet(amount: amount, result: result)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func triggerHaptic(type: String) {
        let generator: UIFeedbackGenerator
        
        switch type {
        case "light":
            generator = UIImpactFeedbackGenerator(style: .light)
        case "medium":
            generator = UIImpactFeedbackGenerator(style: .medium)
        case "heavy":
            generator = UIImpactFeedbackGenerator(style: .heavy)
        case "success":
            generator = UINotificationFeedbackGenerator()
            (generator as? UINotificationFeedbackGenerator)?.notificationOccurred(.success)
            return
        case "warning":
            generator = UINotificationFeedbackGenerator()
            (generator as? UINotificationFeedbackGenerator)?.notificationOccurred(.warning)
            return
        case "error":
            generator = UINotificationFeedbackGenerator()
            (generator as? UINotificationFeedbackGenerator)?.notificationOccurred(.error)
            return
        default:
            generator = UIImpactFeedbackGenerator(style: .medium)
        }
        
        generator.prepare()
        (generator as? UIImpactFeedbackGenerator)?.impactOccurred()
    }
    
    private func authenticateBiometric(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Free Rider 인증"
            ) { success, error in
                DispatchQueue.main.async {
                    result(success)
                }
            }
        } else {
            result(false)
        }
    }
    
    private func chargeMobileWallet(amount: Int, result: @escaping FlutterResult) {
        // Apple Pay integration
        result(true)
    }
}
```

---

## 9. Performance Optimization

### 9.1 Performance Best Practices

```dart
// lib/core/utils/performance.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PerformanceUtils {
  // Image Caching
  static void precacheImages(BuildContext context) {
    final images = [
      'assets/images/logo.png',
      'assets/images/card_bg.png',
      'assets/images/tmoney_logo.png',
      'assets/images/cashbee_logo.png',
    ];
    
    for (final image in images) {
      precacheImage(AssetImage(image), context);
    }
  }
  
  // Debouncing
  static void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    Timer? timer;
    timer?.cancel();
    timer = Timer(delay, callback);
  }
  
  // Frame Scheduling
  static void scheduleFrame(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
}

// Optimized List View
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollPhysics? physics;
  
  const OptimizedListView({
    super.key,
    required this.children,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
      physics: physics ?? const BouncingScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      cacheExtent: 100.0,
    );
  }
}

// Memoized Widget
class MemoizedWidget extends StatelessWidget {
  final Widget Function() builder;
  final List<Object?> dependencies;
  
  const MemoizedWidget({
    super.key,
    required this.builder,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return builder();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MemoizedWidget) return false;
    return listEquals(dependencies, other.dependencies);
  }

  @override
  int get hashCode => dependencies.hashCode;
}
```

### 9.2 Build Configuration

```yaml
# .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Free Rider (Debug)",
      "request": "launch",
      "type": "dart",
      "args": ["--flavor", "dev"]
    },
    {
      "name": "Free Rider (Profile)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "profile",
      "args": ["--flavor", "staging"]
    },
    {
      "name": "Free Rider (Release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "args": ["--flavor", "prod"]
    }
  ]
}

# Build commands
# Android
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols

# iOS
flutter build ios --release --obfuscate --split-debug-info=build/symbols
```

---

## 10. Testing Guide

### 10.1 Widget Tests

```dart
// test/widgets/primary_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_rider/presentation/widgets/buttons/primary_button.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('displays text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Test',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test'), findsNothing);
    });

    testWidgets('triggers onPressed callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Test',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(pressed, true);
    });
  });
}
```

### 10.2 Integration Tests

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:free_rider/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('Complete user flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen
      await tester.pump(const Duration(seconds: 3));

      // Onboarding
      expect(find.text('교통비가 사라집니다'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      // Home screen
      expect(find.text('오늘의 교통비'), findsOneWidget);
      
      // Watch ad
      await tester.tap(find.text('광고'));
      await tester.pumpAndSettle();
      
      // Complete ad viewing
      await tester.pump(const Duration(seconds: 30));
      
      // Check points earned
      expect(find.text('+100P'), findsOneWidget);
    });
  });
}
```

---

## Appendix

### Utils & Formatters

```dart
// lib/core/utils/formatters.dart
class Formatters {
  static String currency(int amount) {
    return '₩${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  static String cardNumber(String number) {
    return number.replaceAllMapped(
      RegExp(r'.{4}'),
      (Match m) => '${m.group(0)} ',
    ).trim();
  }

  static String phoneNumber(String number) {
    if (number.length == 11) {
      return '${number.substring(0, 3)}-${number.substring(3, 7)}-${number.substring(7)}';
    }
    return number;
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.month}월 ${dateTime.day}일';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
```

---

**Document Version**: 1.0.0  
**Flutter Version**: 3.16.0+  
**Last Updated**: 2024-08-12  
**Design Team**: Free Rider Design & Development

© 2024 Free Rider. All Rights Reserved.

### 5.1 Point Earn Animation

```dart
// lib/presentation/animations/point_earn_animation.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/responsive.dart';

class PointEarnAnimation extends StatefulWidget {
  final int amount;
  final String source;
  final VoidCallback onComplete;

  const PointEarnAnimation({
    super.key,
    required this.amount,
    required this.source,
    required this.onComplete,
  });

  @override
  State<PointEarnAnimation> createState() => _PointEarnAnimationState();
}

class _PointEarnAnimationState extends State<PointEarnAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _controller.forward().then((_) {
      widget.onComplete();
    });
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Coin Animation
            SizedBox(
              width: 200.w,
              height: 200.w,
              child: Lottie.asset(
                'assets/animations/coin_drop.json',
                controller: _controller,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                },
              ),
            ),
            
            20.verticalSpace,
            
            // Points Text
            Text(
              '+${widget.amount}P',
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.freeGreen,
                fontWeight: FontWeight.bold,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 500.ms)
            .scale(begin: 0.5, end: 1.0),
            
            8.verticalSpace,
            
            // Source Text
            Text(
              widget.source,
              style: AppTypography.body.copyWith(
                color: AppColors.white.withOpacity(0.8),
              ),
            )
            .animate()
            .fadeIn(delay: 700.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/animations/charge_success_animation.dart
class ChargeSuccessAnimation extends StatefulWidget {
  final int amount;
  final VoidCallback onComplete;

  const ChargeSuccessAnimation({
    super.key,
    required this.amount,
    required this.onComplete,
  });

  @override
  State<ChargeSuccessAnimation> createState() => _ChargeSuccessAnimationState();
}

class _ChargeSuccessAnimationState extends State<ChargeSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    
    _startAnimation();
  }

  void _startAnimation() async {
    await _checkController.forward();
    _confettiController.forward();
    HapticFeedback.heavyImpact();
    
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Confetti Background
          Lottie.asset(
            'assets/animations/confetti.json',
            controller: _confettiController,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          
          // Success Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Check Circle
                ScaleTransition(
                  scale: _checkAnimation,
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: 60.sp,
                    ),
                  ),
                ),
                
                32.verticalSpace,
                
                Text(
                  '충전 완료!',
                  style: AppTypography.h1.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
                
                16.verticalSpace,
                
                Text(
                  '${Formatters.currency(widget.amount)}이\n교통카드에 충전되었습니다',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.gray700,
                  ),
                )
                .animate()
                .fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}