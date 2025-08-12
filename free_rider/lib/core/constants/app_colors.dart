import 'package:flutter/material.dart';

/// FREERIDER 앱 컬러 시스템
class AppColors {
  AppColors._();
  
  // Primary Colors - 브랜드 아이덴티티
  static const Color primaryGreen = Color(0xFF00FF88);  // Freedom Green - 자유, 행동
  static const Color primaryGreenLight = Color(0xFF5AFFB0);
  static const Color primaryGreenDark = Color(0xFF00CC6A);
  
  // Secondary Colors
  static const Color seoulBlack = Color(0xFF0A0A0A);  // Seoul Black - 프리미엄
  static const Color rewardOrange = Color(0xFFFF6B35);  // Reward Orange - 보상, 축하
  static const Color subwayBlue = Color(0xFF0066FF);  // Subway Blue - 신뢰, 안정
  
  // Grayscale
  static const Color gray900 = Color(0xFF1A1A1A);
  static const Color gray800 = Color(0xFF2A2A2A);
  static const Color gray700 = Color(0xFF3A3A3A);
  static const Color gray600 = Color(0xFF4A4A4A);
  static const Color gray500 = Color(0xFF6A6A6A);
  static const Color gray400 = Color(0xFF8A8A8A);
  static const Color gray300 = Color(0xFFAAAAAA);
  static const Color gray200 = Color(0xFFCACACA);
  static const Color gray100 = Color(0xFFEAEAEA);
  static const Color gray50 = Color(0xFFF5F5F5);
  
  // Semantic Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFB800);
  static const Color info = Color(0xFF0099FF);
  
  // Background Colors
  static const Color backgroundPrimary = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color backgroundDark = seoulBlack;
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFAFAFA);
  
  // Text Colors
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color textTertiary = gray400;
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  // Border Colors
  static const Color border = gray200;
  static const Color borderLight = gray100;
  static const Color borderDark = gray300;
  
  // Activity Colors - 활동별 포인트 색상
  static const Color movementColor = primaryGreen;  // 이동 포인트
  static const Color breathingColor = Color(0xFF87CEEB);  // 호흡 포인트 (Sky Blue)
  static const Color voiceColor = Color(0xFFFFD700);  // 음성 포인트 (Gold)
  static const Color visualColor = rewardOrange;  // 시각 포인트
  static const Color cognitiveColor = Color(0xFF9B59B6);  // 인지 포인트 (Purple)
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenDark],
  );
  
  static const LinearGradient rewardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rewardOrange, Color(0xFFFF4500)],
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [seoulBlack, gray800],
  );
  
  // Shadow Colors
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowDark = Color(0x29000000);
  
  // Overlay Colors
  static const Color overlayLight = Color(0x0A000000);
  static const Color overlayMedium = Color(0x29000000);
  static const Color overlayDark = Color(0x66000000);
}