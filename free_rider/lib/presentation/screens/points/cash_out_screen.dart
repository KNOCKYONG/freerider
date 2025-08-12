import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/points/cash_out_service.dart';
import '../../../data/providers/points_provider.dart';
import '../../widgets/common/primary_button.dart';

/// 포인트 현금화 화면
/// 교통카드 직접 충전 대신 현금으로 전환
class CashOutScreen extends ConsumerStatefulWidget {
  const CashOutScreen({super.key});

  @override
  ConsumerState<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends ConsumerState<CashOutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CashOutService _cashOutService = CashOutService();
  
  // 현금화 금액 옵션
  final List<int> _quickAmounts = [1550, 3000, 5000, 10000];
  int _selectedAmount = 1550;
  final _customAmountController = TextEditingController();
  
  // 계좌 정보
  BankAccount? _selectedAccount;
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  String _selectedBankCode = '004'; // KB국민은행
  
  // 1원 인증
  final _verificationController = TextEditingController();
  OneWonVerification? _oneWonVerification;
  bool _isVerified = false;
  
  // 상태
  bool _isProcessing = false;
  List<CashOutRecord> _cashOutHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCashOutHistory();
    _loadSavedAccount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customAmountController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  void _loadCashOutHistory() {
    final history = _cashOutService.getCashOutHistory('user_001');
    setState(() {
      _cashOutHistory = history;
    });
  }

  void _loadSavedAccount() {
    // SharedPreferences에서 저장된 계좌 불러오기 (Mock)
    // 실제로는 로컬 저장소에서 불러옴
  }

  @override
  Widget build(BuildContext context) {
    final pointsState = ref.watch(pointsStateProvider);
    final currentPoints = pointsState.totalPoints;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('포인트 현금화'),
        backgroundColor: AppColors.backgroundPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: '현금화 신청'),
            Tab(text: '현금화 내역'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCashOutTab(currentPoints),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCashOutTab(int currentPoints) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // 현재 포인트
          _buildPointsCard(currentPoints),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 현금화 금액 선택
          _buildAmountSelection(currentPoints),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 계좌 정보
          _buildAccountSection(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 현금화 신청 버튼
          PrimaryButton(
            text: _isProcessing ? '처리 중...' : '현금화 신청',
            onPressed: _canRequestCashOut() ? _requestCashOut : null,
            isLoading: _isProcessing,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 안내사항
          _buildInfoSection(),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_cashOutHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '현금화 내역이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: AppSpacing.screenPaddingHorizontal,
      itemCount: _cashOutHistory.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(_cashOutHistory[index]);
      },
    );
  }

  Widget _buildPointsCard(int points) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppSpacing.shadowMd,
      ),
      child: Column(
        children: [
          Text(
            '현재 보유 포인트',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${points.toStringAsFixed(0)}P',
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '≈ ${points.toStringAsFixed(0)}원',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildAmountSelection(int currentPoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '현금화 금액',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // 빠른 선택 버튼
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _quickAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;
            final isAvailable = currentPoints >= amount;
            
            return ChoiceChip(
              label: Text('${amount}P'),
              selected: isSelected,
              onSelected: isAvailable ? (selected) {
                setState(() {
                  _selectedAmount = amount;
                  _customAmountController.clear();
                });
              } : null,
              selectedColor: AppColors.primaryGreen.withOpacity(0.2),
              backgroundColor: isAvailable ? AppColors.surface : AppColors.gray100,
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected 
                    ? AppColors.primaryGreen
                    : isAvailable 
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected 
                    ? AppColors.primaryGreen
                    : isAvailable
                        ? AppColors.border
                        : AppColors.gray200,
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // 직접 입력
        TextField(
          controller: _customAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '직접 입력',
            hintText: '최소 1,550P',
            suffixText: 'P',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _selectedAmount = int.tryParse(value) ?? 0;
              });
            }
          },
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // 한도 표시
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '일일 한도: ${_cashOutService.getRemainingDailyLimit()}원 / '
                '월간 한도: ${_cashOutService.getRemainingMonthlyLimit()}원',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '입금 계좌',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isVerified)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '인증완료',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        
        // 은행 선택
        DropdownButtonFormField<String>(
          value: _selectedBankCode,
          decoration: InputDecoration(
            labelText: '은행',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          items: SupportedBanks.banks.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBankCode = value!;
              _isVerified = false;
            });
          },
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // 계좌번호
        TextField(
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '계좌번호',
            hintText: '숫자만 입력',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          onChanged: (_) => setState(() => _isVerified = false),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // 예금주
        TextField(
          controller: _accountHolderController,
          decoration: InputDecoration(
            labelText: '예금주',
            hintText: '계좌 소유자 이름',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          onChanged: (_) => setState(() => _isVerified = false),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // 1원 인증
        if (!_isVerified) ...[
          OutlinedButton(
            onPressed: _canRequestVerification() ? _requestVerification : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: BorderSide(color: AppColors.primaryGreen),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '1원 인증하기',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // 인증번호 입력
        if (_oneWonVerification != null && !_isVerified) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _verificationController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '입금자명 뒤 4자리',
                    hintText: '0000',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: const Text('확인'),
              ),
            ],
          ),
        ],
      ],
    );
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
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '현금화 안내',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• 평일 오전 11시 이전 신청: 당일 입금\n'
            '• 평일 오후 및 주말 신청: 익영업일 입금\n'
            '• 수수료: 무료\n'
            '• 최소 금액: 1,550P\n'
            '• 1P = 1원으로 교환',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(CashOutRecord record) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (record.status) {
      case CashOutStatus.completed:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = '완료';
        break;
      case CashOutStatus.pending:
      case CashOutStatus.processing:
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
        statusText = '처리중';
        break;
      case CashOutStatus.failed:
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
        statusText = '실패';
        break;
      case CashOutStatus.cancelled:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.cancel_rounded;
        statusText = '취소';
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 20, color: statusColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    statusText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(record.requestedAt),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.amount}원',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${record.points}P 사용',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.bankAccount.bankName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _maskAccountNumber(record.bankAccount.accountNumber),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (record.memo != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(
                record.memo!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canRequestCashOut() {
    return _selectedAmount >= CashOutService.minimumCashOutPoints &&
           _isVerified &&
           !_isProcessing;
  }

  bool _canRequestVerification() {
    return _accountNumberController.text.isNotEmpty &&
           _accountHolderController.text.isNotEmpty;
  }

  Future<void> _requestVerification() async {
    setState(() => _isProcessing = true);
    
    final account = BankAccount(
      bankCode: _selectedBankCode,
      bankName: SupportedBanks.banks[_selectedBankCode]!,
      accountNumber: _accountNumberController.text,
      accountHolder: _accountHolderController.text,
    );
    
    try {
      final verification = await _cashOutService.requestOneWonVerification(account);
      setState(() {
        _oneWonVerification = verification;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1원이 입금되었습니다. 입금자명을 확인해주세요'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 요청 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_oneWonVerification == null) return;
    
    final isValid = await _cashOutService.verifyOneWon(
      _accountNumberController.text,
      _verificationController.text,
      _oneWonVerification!.verificationCode,
    );
    
    if (isValid) {
      setState(() {
        _isVerified = true;
        _selectedAccount = BankAccount(
          bankCode: _selectedBankCode,
          bankName: SupportedBanks.banks[_selectedBankCode]!,
          accountNumber: _accountNumberController.text,
          accountHolder: _accountHolderController.text,
          isVerified: true,
          verifiedAt: DateTime.now(),
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계좌 인증이 완료되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호가 일치하지 않습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _requestCashOut() async {
    if (_selectedAccount == null) return;
    
    setState(() => _isProcessing = true);
    
    final result = await _cashOutService.requestCashOut(
      userId: 'user_001',
      points: _selectedAmount,
      bankAccount: _selectedAccount!,
      memo: '교통비 현금화',
    );
    
    setState(() => _isProcessing = false);
    
    if (result.success) {
      // 포인트 차감
      ref.read(pointsStateProvider.notifier).usePoints(
        _selectedAmount,
        '현금화',
      );
      
      // 내역 새로고침
      _loadCashOutHistory();
      
      // 성공 다이얼로그
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                const Text('현금화 신청 완료'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.expectedAmount}원이 입금 예정입니다',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '예상 입금일: ${_formatDate(result.expectedDate!)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _tabController.animateTo(1); // 내역 탭으로 이동
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? '현금화 신청 실패'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final visible = accountNumber.substring(accountNumber.length - 4);
    return '****$visible';
  }
}