import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../routes/app_router.dart';
import '../../widgets/common/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '매일 무료 교통비\n1,550원을 받으세요',
      description: '일상 활동으로 포인트를 모아\n하루 교통비를 무료로 충전하세요',
      icon: Icons.directions_subway_rounded,
      color: AppColors.primaryGreen,
    ),
    OnboardingPage(
      title: '움직이면 포인트가\n자동으로 쌓여요',
      description: '걷기, 계단 오르기, 자전거 타기\n모든 이동이 포인트가 됩니다',
      icon: Icons.directions_walk_rounded,
      color: AppColors.subwayBlue,
    ),
    OnboardingPage(
      title: '광고 시청하고\n추가 포인트 받기',
      description: '짧은 광고 시청으로\n더 빠르게 교통비를 모으세요',
      icon: Icons.play_circle_outline_rounded,
      color: AppColors.rewardOrange,
    ),
    OnboardingPage(
      title: '교통카드에\n자동으로 충전',
      description: 'T-money, Cashbee 등\n모든 교통카드에 바로 충전됩니다',
      icon: Icons.credit_card_rounded,
      color: AppColors.primaryGreen,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _startCardRegistration();
    }
  }

  void _skipOnboarding() {
    _startCardRegistration();
  }

  void _startCardRegistration() {
    // Navigate to card registration
    context.go('${AppRoutes.main}/card-registration');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  '건너뛰기',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),
            
            // Bottom Section
            Padding(
              padding: AppSpacing.screenPaddingHorizontal,
              child: Column(
                children: [
                  // Page Indicator
                  _buildPageIndicator(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Next Button
                  PrimaryButton(
                    text: _currentPage == _pages.length - 1 
                        ? '시작하기' 
                        : '다음',
                    onPressed: _nextPage,
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.color,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .shimmer(
                duration: 3000.ms,
                color: page.color.withOpacity(0.3),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms),
          
          const SizedBox(height: AppSpacing.xxxl),
          
          // Title
          Text(
            page.title,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Description
          Text(
            page.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index 
                ? AppColors.primaryGreen 
                : AppColors.gray300,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}