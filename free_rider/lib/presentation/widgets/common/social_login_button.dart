import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';

class SocialLoginButton extends StatelessWidget {
  final String provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getProviderConfig(provider);
    
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeightLg,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: config.backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            side: BorderSide(
              color: config.borderColor ?? Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            _buildProviderIcon(config),
            const SizedBox(width: AppSpacing.sm),
            // Text
            Text(
              config.text,
              style: AppTypography.buttonLarge.copyWith(
                color: config.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderIcon(_ProviderConfig config) {
    switch (provider) {
      case 'kakao':
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/kakao_icon.png'),
              fit: BoxFit.contain,
            ),
          ),
        );
      case 'apple':
        return Icon(
          Icons.apple,
          size: 24,
          color: config.iconColor,
        );
      case 'google':
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/google_icon.png'),
              fit: BoxFit.contain,
            ),
          ),
        );
      case 'naver':
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Color(0xFF03C75A),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  _ProviderConfig _getProviderConfig(String provider) {
    switch (provider) {
      case 'kakao':
        return _ProviderConfig(
          backgroundColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF000000),
          iconColor: const Color(0xFF000000),
          text: '카카오로 시작하기',
        );
      case 'apple':
        return _ProviderConfig(
          backgroundColor: const Color(0xFF000000),
          textColor: const Color(0xFFFFFFFF),
          iconColor: const Color(0xFFFFFFFF),
          text: 'Apple로 시작하기',
        );
      case 'google':
        return _ProviderConfig(
          backgroundColor: const Color(0xFFFFFFFF),
          textColor: const Color(0xFF3C4043),
          iconColor: null,
          text: 'Google로 시작하기',
          borderColor: AppColors.border,
        );
      case 'naver':
        return _ProviderConfig(
          backgroundColor: const Color(0xFF03C75A),
          textColor: const Color(0xFFFFFFFF),
          iconColor: const Color(0xFFFFFFFF),
          text: '네이버로 시작하기',
        );
      default:
        return _ProviderConfig(
          backgroundColor: AppColors.gray100,
          textColor: AppColors.textPrimary,
          iconColor: AppColors.textPrimary,
          text: '소셜 로그인',
        );
    }
  }
}

class _ProviderConfig {
  final Color backgroundColor;
  final Color textColor;
  final Color? iconColor;
  final String text;
  final Color? borderColor;

  _ProviderConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.text,
    this.borderColor,
  });
}