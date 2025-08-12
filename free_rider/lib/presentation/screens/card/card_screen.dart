import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/points_provider.dart';
import '../points/cash_out_screen.dart';
import '../../widgets/common/primary_button.dart';

class CardScreen extends ConsumerWidget {
  const CardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsState = ref.watch(pointsStateProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('포인트 & 현금화'),
        backgroundColor: AppColors.backgroundPrimary,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPaddingHorizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            
            // 포인트 카드
            _buildPointsCard(context, pointsState),
            
            const SizedBox(height: AppSpacing.xl),
            
            // 현금화 버튼
            _buildCashOutSection(context, pointsState),
            
            const SizedBox(height: AppSpacing.xl),
            
            // 안내 메시지
            _buildInfoCard(),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPointsCard(BuildContext context, PointsState pointsState) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.shadowLg,
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // 카드 내용
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 카드 타입
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'FREERIDER POINTS',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.contactless_rounded,
                      size: 32,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
                
                // 포인트
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보유 포인트',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${pointsState.totalPoints}P',
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '≈ ${pointsState.totalPoints}원',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }
  
  Widget _buildCashOutSection(BuildContext context, PointsState pointsState) {
    final canCashOut = pointsState.totalPoints >= 1550;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCashOut) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.celebration_rounded,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현금화 가능!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '포인트를 현금으로 바꿔보세요',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppSpacing.md),
        ],
        
        PrimaryButton(
          text: canCashOut ? '현금화하기' : '포인트 모으기 (${1550 - pointsState.totalPoints}P 부족)',
          onPressed: canCashOut 
              ? () => _navigateToCashOut(context)
              : null,
          icon: canCashOut ? Icons.account_balance_rounded : Icons.lock_rounded,
        ),
        
        if (!canCashOut) ...[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: pointsState.totalPoints / 1550,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '최소 1,550P부터 현금화 가능합니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '이용 안내',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildInfoItem(
            Icons.attach_money_rounded,
            '1P = 1원',
            '포인트는 1:1 비율로 현금 전환',
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          _buildInfoItem(
            Icons.schedule_rounded,
            '빠른 입금',
            '평일 오전 신청 시 당일 입금',
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          _buildInfoItem(
            Icons.money_off_rounded,
            '수수료 무료',
            '현금화 수수료 없음',
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          _buildInfoItem(
            Icons.security_rounded,
            '안전한 거래',
            '1원 인증으로 계좌 확인',
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _navigateToCashOut(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CashOutScreen(),
      ),
    );
  }
}