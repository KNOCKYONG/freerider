import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/ad_provider.dart';
import '../../../data/models/ad_model.dart';
import '../../widgets/common/primary_button.dart';

class AdViewingScreen extends ConsumerStatefulWidget {
  const AdViewingScreen({super.key});

  @override
  ConsumerState<AdViewingScreen> createState() => _AdViewingScreenState();
}

class _AdViewingScreenState extends ConsumerState<AdViewingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _adTimer;
  int _secondsRemaining = 0;
  bool _adCompleted = false;
  bool _isWatching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  void _startAd(AdModel ad) {
    setState(() {
      _isWatching = true;
      _secondsRemaining = ad.duration;
      _adCompleted = false;
    });

    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          timer.cancel();
          _completeAd(ad);
        }
      });
    });
  }

  void _completeAd(AdModel ad) {
    setState(() {
      _adCompleted = true;
      _isWatching = false;
    });
    
    // Award points
    ref.read(adStateProvider.notifier).completeAd(ad.id);
    
    // Show success dialog
    _showRewardDialog(ad.points);
  }

  void _skipAd() {
    _adTimer?.cancel();
    setState(() {
      _isWatching = false;
      _secondsRemaining = 0;
      _adCompleted = false;
    });
  }

  void _showRewardDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 40,
                  color: AppColors.primaryGreen,
                ),
              ).animate().scale(duration: 300.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                '포인트 획득!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${points}P',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: '확인',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(adStateProvider);
    final availableAds = ref.watch(availableAdsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('광고 시청'),
        backgroundColor: AppColors.backgroundPrimary,
      ),
      body: _isWatching
          ? _buildAdPlayer()
          : SingleChildScrollView(
              padding: AppSpacing.screenPaddingHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  
                  // Daily Summary Card
                  _buildDailySummary(adState),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Available Ads Section
                  _buildAvailableAds(availableAds),
                  
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildAdPlayer() {
    return Container(
      color: AppColors.seoulBlack,
      child: Stack(
        children: [
          // Mock Ad Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(
                          0.3 + 0.3 * _animationController.value,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '광고 재생 중',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${_secondsRemaining}초 남음',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Skip Button (disabled for first 5 seconds)
          if (_secondsRemaining < 25)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              right: AppSpacing.md,
              child: TextButton.icon(
                onPressed: _skipAd,
                icon: const Icon(Icons.close, color: Colors.white70),
                label: Text(
                  '건너뛰기',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black45,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ),
          
          // Progress Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: 1 - (_secondsRemaining / 30),
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(AdState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.rewardOrange.withOpacity(0.9),
            AppColors.rewardOrange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.shadowLg,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘 획득 포인트',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${state.todayPoints}P',
                    style: AppTypography.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.movie_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '시청 완료',
                  '${state.watchedCount}개',
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildSummaryItem(
                  '남은 광고',
                  '${AppConstants.adDailyLimit - state.watchedCount}개',
                  Icons.access_time,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableAds(List<AdModel> ads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시청 가능한 광고',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        if (ads.isEmpty)
          _buildEmptyState()
        else
          ...ads.map((ad) => _buildAdCard(ad)).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 48,
            color: AppColors.gray300,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '오늘의 광고를 모두 시청했어요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '내일 다시 확인해주세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(AdModel ad) {
    final isWatched = ref.watch(adStateProvider).watchedAdIds.contains(ad.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isWatched ? AppColors.gray200 : AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isWatched ? null : () => _startAd(ad),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: ad.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 32,
                    color: isWatched ? AppColors.gray300 : ad.color,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isWatched ? AppColors.textTertiary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      ad.advertiser,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${ad.duration}초',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Points
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isWatched 
                      ? AppColors.gray100 
                      : AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  isWatched ? '완료' : '+${ad.points}P',
                  style: AppTypography.labelMedium.copyWith(
                    color: isWatched ? AppColors.textTertiary : AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * ads.indexOf(ad)));
  }
}