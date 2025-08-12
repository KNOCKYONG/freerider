import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/payment/mobile_pay_service.dart';
import '../../widgets/common/primary_button.dart';

/// 모바일 페이 연동 테스트 화면
/// Samsung Pay, Apple Pay 통합 테스트
class PaymentTestScreen extends ConsumerStatefulWidget {
  const PaymentTestScreen({super.key});

  @override
  ConsumerState<PaymentTestScreen> createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends ConsumerState<PaymentTestScreen> {
  final MobilePayService _payService = MobilePayService();
  bool _isAvailable = false;
  bool _isLoading = false;
  String _statusMessage = '초기화 중...';
  List<TransitCardInfo> _registeredCards = [];
  
  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }
  
  Future<void> _checkAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      // 모바일 페이 사용 가능 여부 확인
      final available = await _payService.isAvailable();
      
      setState(() {
        _isAvailable = available;
        _statusMessage = available 
            ? '✅ 모바일 페이 사용 가능' 
            : '⚠️ 모바일 페이 사용 불가';
      });
      
      if (available) {
        await _loadRegisteredCards();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 오류: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadRegisteredCards() async {
    try {
      final cards = await _payService.getRegisteredCards();
      setState(() {
        _registeredCards = cards;
      });
    } catch (e) {
      print('Failed to load cards: $e');
    }
  }
  
  Future<void> _testPayment() async {
    if (!_isAvailable || _registeredCards.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _payService.chargeTransitCard(
        cardId: _registeredCards.first.id,
        amount: 1550,
        cardType: _registeredCards.first.type,
      );
      
      if (result.success) {
        _showResultDialog(
          '결제 성공',
          '거래 ID: ${result.transactionId}\n잔액: ${result.balance ?? 'N/A'}원',
          true,
        );
      } else {
        _showResultDialog(
          '결제 실패',
          result.errorMessage ?? '알 수 없는 오류',
          false,
        );
      }
    } catch (e) {
      _showResultDialog('오류', e.toString(), false);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _testNFCPayment() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _payService.chargeNFCCard(
        cardNumber: '1234567890123456',
        amount: 1550,
      );
      
      if (result.success) {
        _showResultDialog(
          'NFC 충전 성공',
          '거래 ID: ${result.transactionId}\n새 잔액: ${result.balance}원',
          true,
        );
      } else {
        _showResultDialog(
          'NFC 충전 실패',
          result.errorMessage ?? '알 수 없는 오류',
          false,
        );
      }
    } catch (e) {
      _showResultDialog('오류', e.toString(), false);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showResultDialog(String title, String message, bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? AppColors.primaryGreen : AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('모바일 페이 테스트'),
        backgroundColor: AppColors.backgroundPrimary,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPaddingHorizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            
            // 상태 표시
            _buildStatusCard(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // 등록된 카드 목록
            if (_registeredCards.isNotEmpty) ...[
              _buildCardsList(),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // 테스트 버튼들
            _buildTestButtons(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // 테스트 정보
            _buildTestInfo(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _isAvailable ? AppColors.primaryGreen.withOpacity(0.1) : AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _isAvailable ? AppColors.primaryGreen : AppColors.gray300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.warning,
            size: 48,
            color: _isAvailable ? AppColors.primaryGreen : AppColors.gray500,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _statusMessage,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCardsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '등록된 카드',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._registeredCards.map((card) => _buildCardItem(card)),
      ],
    );
  }
  
  Widget _buildCardItem(TransitCardInfo card) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card,
            color: AppColors.subwayBlue,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.type,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '•••• ${card.lastFourDigits}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₩${card.balance}',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestButtons() {
    return Column(
      children: [
        PrimaryButton(
          text: '모바일 페이 충전 테스트',
          onPressed: _isAvailable && !_isLoading ? _testPayment : null,
          isLoading: _isLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          text: 'NFC 카드 충전 테스트',
          onPressed: !_isLoading ? _testNFCPayment : null,
          isLoading: _isLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: _checkAvailability,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            side: BorderSide(color: AppColors.primaryGreen),
          ),
          child: Text(
            '상태 다시 확인',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTestInfo() {
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
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '테스트 정보',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• 실제 결제는 처리되지 않습니다\n'
            '• Samsung Pay/Apple Pay SDK 연동 확인\n'
            '• NFC 충전은 Android에서만 가능\n'
            '• 실제 서비스 시 Merchant ID 필요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}