import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/card_provider.dart';
import '../../../data/models/card_model.dart';
import '../../../services/payment/mobile_pay_service.dart';
import '../../widgets/common/primary_button.dart';
import 'bank_transfer_screen.dart';

class CardChargingScreen extends ConsumerStatefulWidget {
  const CardChargingScreen({super.key});

  @override
  ConsumerState<CardChargingScreen> createState() => _CardChargingScreenState();
}

class _CardChargingScreenState extends ConsumerState<CardChargingScreen>
    with TickerProviderStateMixin {
  late AnimationController _chargingController;
  late AnimationController _successController;
  final MobilePayService _mobilePayService = MobilePayService();
  bool _isCharging = false;
  bool _chargeComplete = false;
  bool _useMobilePay = false;
  bool _mobilePayAvailable = false;

  @override
  void initState() {
    super.initState();
    _chargingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkMobilePayAvailability();
  }

  Future<void> _checkMobilePayAvailability() async {
    try {
      final isAvailable = await _mobilePayService.isAvailable();
      if (mounted) {
        setState(() {
          _mobilePayAvailable = isAvailable;
          _useMobilePay = isAvailable; // Default to mobile pay if available
        });
      }
    } catch (e) {
      // Mobile pay not available
      if (mounted) {
        setState(() {
          _mobilePayAvailable = false;
          _useMobilePay = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _chargingController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _chargeCard() async {
    if (_isCharging) return;
    
    final cardState = ref.read(cardStateProvider);
    if (cardState.currentPoints < AppConstants.dailyTargetPoints) {
      _showInsufficientPointsDialog();
      return;
    }
    
    setState(() {
      _isCharging = true;
      _chargeComplete = false;
    });
    
    _chargingController.repeat();
    
    try {
      // Check if mobile pay is available and use it
      if (_useMobilePay) {
        final isAvailable = await _mobilePayService.isAvailable();
        if (isAvailable && cardState.selectedCard != null) {
          // Use mobile pay for actual charging
          final result = await _mobilePayService.chargeTransitCard(
            cardId: cardState.selectedCard!.id,
            amount: AppConstants.dailyTargetPoints,
            cardType: cardState.selectedCard!.type,
          );
          
          if (!result.success) {
            throw Exception(result.errorMessage ?? 'Mobile pay failed');
          }
        } else {
          // Fallback to simulation
          await Future.delayed(const Duration(seconds: 3));
        }
      } else {
        // Simulate charging process
        await Future.delayed(const Duration(seconds: 3));
      }
      
      // Update local state
      ref.read(cardStateProvider.notifier).chargeCard(
        AppConstants.dailyTargetPoints,
      );
      
      _chargingController.stop();
      _successController.forward();
      
      setState(() {
        _isCharging = false;
        _chargeComplete = true;
      });
      
      // Show success message
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _chargingController.stop();
      setState(() {
        _isCharging = false;
        _chargeComplete = false;
      });
      
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showInsufficientPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Text(
          '포인트 부족',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '충전에 필요한 ${AppConstants.dailyTargetPoints}P가 부족합니다.\n활동을 통해 포인트를 모아주세요!',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '충전 실패',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          '충전 중 오류가 발생했습니다.\n$error',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '충전 완료!',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${AppConstants.dailyTargetPoints}원이 충전되었습니다',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: '확인',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardState = ref.watch(cardStateProvider);
    final canCharge = cardState.currentPoints >= AppConstants.dailyTargetPoints;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('교통카드 충전'),
        backgroundColor: AppColors.backgroundPrimary,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPaddingHorizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            
            // Card Visual
            _buildCardVisual(cardState),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Points Status
            _buildPointsStatus(cardState),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Charging Animation/Status
            if (_isCharging || _chargeComplete)
              _buildChargingStatus(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Payment Method Selection (if mobile pay is available)
            if (_mobilePayAvailable) ...[
              _buildPaymentMethodSelection(),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // Charge Button
            PrimaryButton(
              text: _isCharging 
                  ? '충전 중...'
                  : _useMobilePay 
                      ? '모바일 페이로 충전하기'
                      : '교통카드 충전하기',
              onPressed: canCharge && !_isCharging ? _chargeCard : null,
              isLoading: _isCharging,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Bank Transfer Option
            if (!_mobilePayAvailable || !_useMobilePay) ...[
              OutlinedButton(
                onPressed: !_isCharging ? () => _navigateToBankTransfer() : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  side: BorderSide(
                    color: AppColors.primaryGreen,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '계좌이체로 충전하기',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            
            // Info Text
            _buildInfoSection(),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildCardVisual(CardState state) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.subwayBlue,
            AppColors.subwayBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.shadowLg,
      ),
      child: Stack(
        children: [
          // Card Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/card_pattern.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          
          // Card Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Card Type
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
                        state.selectedCard?.type ?? 'T-money',
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
                
                // Card Number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '카드 번호',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      state.selectedCard?.maskedNumber ?? '•••• •••• •••• 1234',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                
                // Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '잔액',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '₩${state.selectedCard?.balance ?? 0}',
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (_isCharging)
                      AnimatedBuilder(
                        animation: _chargingController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _chargingController.value * 2 * 3.14159,
                            child: Icon(
                              Icons.sync_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          );
                        },
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

  Widget _buildPointsStatus(CardState state) {
    final hasEnoughPoints = state.currentPoints >= AppConstants.dailyTargetPoints;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasEnoughPoints ? AppColors.primaryGreen : AppColors.border,
          width: 1,
        ),
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
                    '보유 포인트',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${state.currentPoints}P',
                    style: AppTypography.headlineSmall.copyWith(
                      color: hasEnoughPoints 
                          ? AppColors.primaryGreen 
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '충전 필요',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${AppConstants.dailyTargetPoints}P',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: (state.currentPoints / AppConstants.dailyTargetPoints)
                  .clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                hasEnoughPoints ? AppColors.primaryGreen : AppColors.gray400,
              ),
            ),
          ),
          if (!hasEnoughPoints) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${AppConstants.dailyTargetPoints - state.currentPoints}P 더 필요해요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.rewardOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargingStatus() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (_isCharging) ...[
            Icon(
              Icons.bolt_rounded,
              size: 48,
              color: AppColors.primaryGreen,
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).scale(
              duration: 500.ms,
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
            ).then().scale(
              duration: 500.ms,
              begin: const Offset(1.2, 1.2),
              end: const Offset(1, 1),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '충전 진행 중...',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (_chargeComplete) ...[
            Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: AppColors.primaryGreen,
            ).animate().scale(
              duration: 300.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '충전 성공!',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '충전 안내',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoItem('• 1,550P를 모으면 자동으로 충전 가능'),
          _buildInfoItem('• 충전된 금액은 교통카드에 즉시 반영'),
          _buildInfoItem('• 하루 1회 충전 가능'),
          _buildInfoItem('• 모든 대중교통 이용 가능'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '충전 방법 선택',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _useMobilePay = true),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _useMobilePay 
                          ? AppColors.primaryGreen.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: _useMobilePay 
                            ? AppColors.primaryGreen
                            : AppColors.border,
                        width: _useMobilePay ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone_android_rounded,
                          color: _useMobilePay 
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '모바일 페이',
                          style: AppTypography.bodySmall.copyWith(
                            color: _useMobilePay 
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _useMobilePay = false),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: !_useMobilePay 
                          ? AppColors.primaryGreen.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: !_useMobilePay 
                            ? AppColors.primaryGreen
                            : AppColors.border,
                        width: !_useMobilePay ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.credit_card_rounded,
                          color: !_useMobilePay 
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '직접 충전',
                          style: AppTypography.bodySmall.copyWith(
                            color: !_useMobilePay 
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToBankTransfer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BankTransferScreen(),
      ),
    );
  }
}