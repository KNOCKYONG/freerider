import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/points_provider.dart';

/// 네이티브 광고 위젯
/// 피드 내 자연스럽게 노출되는 광고
class NativeAdWidget extends ConsumerStatefulWidget {
  final String placementId;
  final NativeAdStyle style;
  final Function(int points)? onAdClicked;
  
  const NativeAdWidget({
    super.key,
    required this.placementId,
    this.style = NativeAdStyle.medium,
    this.onAdClicked,
  });

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  
  // 클릭당 포인트
  static const int clickPoints = 10;
  static const int viewPoints = 2;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: _getAdUnitId(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
          // 광고 노출 포인트
          ref.read(pointsStateProvider.notifier).addPoints(
            viewPoints,
            '광고 노출',
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native ad failed to load: ${error.message}');
        },
        onAdClicked: (ad) {
          // 광고 클릭 포인트
          ref.read(pointsStateProvider.notifier).addPoints(
            clickPoints,
            '광고 클릭',
          );
          widget.onAdClicked?.call(clickPoints);
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: _getNativeTemplateStyle(),
    );
    
    _nativeAd!.load();
  }

  String _getAdUnitId() {
    // 실제 배포 시 AdMob 콘솔에서 발급받은 ID 사용
    return 'ca-app-pub-3940256099942544/2247696110'; // 테스트 ID
  }

  NativeTemplateStyle _getNativeTemplateStyle() {
    return NativeTemplateStyle(
      templateType: widget.style == NativeAdStyle.small
          ? TemplateType.small
          : TemplateType.medium,
      mainBackgroundColor: AppColors.surface,
      cornerRadius: AppSpacing.radiusMd,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: AppColors.primaryGreen,
        style: NativeTemplateFontStyle.normal,
        size: 14,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textPrimary,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.bold,
        size: 16,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textSecondary,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 14,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textTertiary,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return widget.style == NativeAdStyle.custom
          ? _buildCustomAdPlaceholder()
          : const SizedBox.shrink();
    }

    if (widget.style == NativeAdStyle.custom) {
      return _buildCustomNativeAd();
    }

    // 표준 네이티브 광고
    return Container(
      height: widget.style == NativeAdStyle.small ? 120 : 320,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: AdWidget(ad: _nativeAd!),
    );
  }

  Widget _buildCustomNativeAd() {
    // 커스텀 디자인의 네이티브 광고
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 광고 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  '광고',
                  style: AppTypography.labelXSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '+${viewPoints}P',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Mock 광고 콘텐츠 (실제로는 AdWidget 사용)
          _buildMockAdContent(),
          
          const SizedBox(height: AppSpacing.md),
          
          // CTA 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(pointsStateProvider.notifier).addPoints(
                  clickPoints,
                  '광고 클릭',
                );
                widget.onAdClicked?.call(clickPoints);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('자세히 보기'),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '+${clickPoints}P',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockAdContent() {
    // Mock 광고 콘텐츠 (실제 구현 시 제거)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 플레이스홀더
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: AppColors.gray400,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '광고 이미지',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // 광고 제목
        Text(
          '새로운 서비스를 만나보세요',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xs),
        
        // 광고 설명
        Text(
          '지금 가입하면 특별한 혜택이! 첫 달 무료 이용 기회를 놓치지 마세요.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAdPlaceholder() {
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.gray400,
          ),
        ),
      ),
    );
  }
}

/// 네이티브 광고 스타일
enum NativeAdStyle {
  small,   // 작은 크기
  medium,  // 중간 크기
  large,   // 큰 크기
  custom,  // 커스텀 디자인
}

/// 피드용 네이티브 광고 위젯
class FeedNativeAdWidget extends ConsumerWidget {
  final int index;
  final Widget child;
  final int adInterval; // 몇 개마다 광고 표시
  
  const FeedNativeAdWidget({
    super.key,
    required this.index,
    required this.child,
    this.adInterval = 5, // 기본값: 5개마다 광고
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 광고 표시 여부 결정
    final shouldShowAd = (index + 1) % adInterval == 0;
    
    if (!shouldShowAd) {
      return child;
    }
    
    return Column(
      children: [
        child,
        NativeAdWidget(
          placementId: 'feed_ad_$index',
          style: index % (adInterval * 2) == 0 
              ? NativeAdStyle.custom 
              : NativeAdStyle.medium,
          onAdClicked: (points) {
            // 클릭 추적
            debugPrint('Feed ad clicked at index $index, earned $points points');
          },
        ),
      ],
    );
  }
}