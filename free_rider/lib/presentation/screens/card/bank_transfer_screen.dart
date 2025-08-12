import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/payment/bank_transfer_service.dart';
import '../../../data/providers/card_provider.dart';
import '../../widgets/common/primary_button.dart';

class BankTransferScreen extends ConsumerStatefulWidget {
  const BankTransferScreen({super.key});

  @override
  ConsumerState<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends ConsumerState<BankTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BankTransferService _bankService = BankTransferService();
  
  // 직접 이체 폼 컨트롤러
  final _accountController = TextEditingController();
  final _holderController = TextEditingController();
  final _pinController = TextEditingController();
  String _selectedBank = 'KB';
  
  // 상태
  bool _isProcessing = false;
  List<BankAccount> _userAccounts = [];
  BankAccount? _selectedAccount;
  QuickTransferType? _selectedQuickType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accountController.dispose();
    _holderController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAccounts() async {
    try {
      final accounts = await _bankService.getUserBankAccounts('user_001');
      setState(() {
        _userAccounts = accounts;
        if (accounts.isNotEmpty) {
          _selectedAccount = accounts.firstWhere(
            (acc) => acc.isDefault,
            orElse: () => accounts.first,
          );
        }
      });
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> _processDirectTransfer() async {
    if (_isProcessing) return;
    
    final cardState = ref.read(cardStateProvider);
    if (cardState.selectedCard == null) {
      _showErrorDialog('등록된 교통카드가 없습니다');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _bankService.processDirectTransfer(
        fromBank: _selectedBank,
        fromAccount: _accountController.text,
        accountHolder: _holderController.text,
        amount: AppConstants.dailyTargetPoints,
        pin: _pinController.text,
        cardId: cardState.selectedCard!.id,
      );

      if (result.success) {
        // 충전 성공
        ref.read(cardStateProvider.notifier).chargeCard(
          AppConstants.dailyTargetPoints,
        );
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result.errorMessage ?? '이체 실패');
      }
    } on BankTransferException catch (e) {
      _showErrorDialog(e.message);
    } catch (e) {
      _showErrorDialog('알 수 없는 오류가 발생했습니다');
    } finally {
      setState(() => _isProcessing = false);
      _pinController.clear();
    }
  }

  Future<void> _processQuickTransfer(QuickTransferType type) async {
    if (_isProcessing) return;
    
    final cardState = ref.read(cardStateProvider);
    if (cardState.selectedCard == null) {
      _showErrorDialog('등록된 교통카드가 없습니다');
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedQuickType = type;
    });

    try {
      final result = await _bankService.processQuickTransfer(
        type: type,
        amount: AppConstants.dailyTargetPoints,
        cardId: cardState.selectedCard!.id,
      );

      if (result.success) {
        ref.read(cardStateProvider.notifier).chargeCard(
          AppConstants.dailyTargetPoints,
        );
        _showQuickTransferSuccess(type, result);
      } else {
        _showErrorDialog(result.errorMessage ?? '송금 실패');
      }
    } catch (e) {
      _showErrorDialog('간편 송금 실패: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _selectedQuickType = null;
      });
    }
  }

  Future<void> _createVirtualAccount() async {
    if (_isProcessing) return;
    
    final cardState = ref.read(cardStateProvider);
    if (cardState.selectedCard == null) return;

    setState(() => _isProcessing = true);

    try {
      final virtualAccount = await _bankService.createVirtualAccount(
        userId: 'user_001',
        amount: AppConstants.dailyTargetPoints,
        cardType: cardState.selectedCard!.type,
        cardNumber: cardState.selectedCard!.cardNumber,
      );

      _showVirtualAccountDialog(virtualAccount);
    } catch (e) {
      _showErrorDialog('가상계좌 생성 실패: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardState = ref.watch(cardStateProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('계좌이체 충전'),
        backgroundColor: AppColors.backgroundPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: '직접 이체'),
            Tab(text: '간편 송금'),
            Tab(text: '가상계좌'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectTransferTab(),
          _buildQuickTransferTab(),
          _buildVirtualAccountTab(),
        ],
      ),
    );
  }

  Widget _buildDirectTransferTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // 충전 금액 표시
          _buildAmountCard(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 은행 선택
          _buildBankSelector(),
          
          const SizedBox(height: AppSpacing.md),
          
          // 계좌번호 입력
          _buildTextField(
            controller: _accountController,
            label: '계좌번호',
            hint: '숫자만 입력',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 예금주 입력
          _buildTextField(
            controller: _holderController,
            label: '예금주명',
            hint: '계좌 소유자명',
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 비밀번호 입력
          _buildTextField(
            controller: _pinController,
            label: '계좌 비밀번호',
            hint: '4자리',
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 이체 버튼
          PrimaryButton(
            text: '이체하기',
            onPressed: _canTransfer() ? _processDirectTransfer : null,
            isLoading: _isProcessing,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 안내 메시지
          _buildInfoBox(),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildQuickTransferTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // 충전 금액 표시
          _buildAmountCard(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 간편 송금 옵션들
          _buildQuickTransferOption(
            '토스',
            'assets/images/toss_logo.png',
            QuickTransferType.toss,
            AppColors.subwayBlue,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildQuickTransferOption(
            '카카오페이',
            'assets/images/kakaopay_logo.png',
            QuickTransferType.kakaoPay,
            const Color(0xFFFEE500),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildQuickTransferOption(
            '네이버페이',
            'assets/images/naverpay_logo.png',
            QuickTransferType.naverPay,
            const Color(0xFF03C75A),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 안내
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
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
                      '간편 송금 안내',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• 각 앱에 로그인된 상태여야 합니다\n'
                  '• 일일 이체 한도가 적용됩니다\n'
                  '• 충전 금액: 1,550원',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualAccountTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // 가상계좌 안내
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.1),
                  AppColors.primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '가상계좌 발급',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '1회용 가상계좌를 발급받아\n원하는 은행에서 이체할 수 있습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 금액 표시
          _buildAmountCard(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 가상계좌 발급 버튼
          PrimaryButton(
            text: '가상계좌 발급받기',
            onPressed: !_isProcessing ? _createVirtualAccount : null,
            isLoading: _isProcessing,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 주의사항
          Container(
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
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.rewardOrange,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '주의사항',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.rewardOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• 가상계좌는 30분간 유효합니다\n'
                  '• 입금자명은 반드시 본인 이름으로 입금해주세요\n'
                  '• 입금 확인 후 자동으로 충전됩니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '충전 금액',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '₩${AppConstants.dailyTargetPoints}',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '서울 지하철 기본 요금',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '은행 선택',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBank,
              isExpanded: true,
              items: BankTransferService.supportedBanks.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedBank = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
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
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTransferOption(
    String name,
    String imagePath,
    QuickTransferType type,
    Color color,
  ) {
    final isSelected = _selectedQuickType == type;
    
    return InkWell(
      onTap: !_isProcessing ? () => _processQuickTransfer(type) : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: AppTypography.titleLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '터치 한 번으로 간편 송금',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessing && isSelected)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
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
                Icons.security_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '보안 안내',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• 모든 계좌 정보는 암호화되어 전송됩니다\n'
            '• 비밀번호는 저장되지 않습니다\n'
            '• 금융감독원 전자금융거래법 준수',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  bool _canTransfer() {
    return _accountController.text.isNotEmpty &&
           _holderController.text.isNotEmpty &&
           _pinController.text.length == 4 &&
           !_isProcessing;
  }

  void _showSuccessDialog(TransferResult result) {
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
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ).animate().scale(),
              const SizedBox(height: AppSpacing.md),
              Text(
                '이체 완료!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '거래번호: ${result.transactionId}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: '확인',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickTransferSuccess(QuickTransferType type, QuickTransferResult result) {
    final name = type == QuickTransferType.toss ? '토스' :
                  type == QuickTransferType.kakaoPay ? '카카오페이' : '네이버페이';
    
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
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ).animate().scale(),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$name 송금 완료!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '₩${result.amount} 충전 성공',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: '확인',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVirtualAccountDialog(VirtualAccount account) {
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
                  Icons.account_balance,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '가상계좌 발급',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  children: [
                    _buildAccountInfo('은행', account.bankName),
                    const SizedBox(height: AppSpacing.sm),
                    _buildAccountInfo('계좌번호', account.accountNumber),
                    const SizedBox(height: AppSpacing.sm),
                    _buildAccountInfo('입금자명', account.depositorName),
                    const SizedBox(height: AppSpacing.sm),
                    _buildAccountInfo('입금금액', '₩${account.amount}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.rewardOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '30분 내 입금해주세요',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.rewardOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: account.accountNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('계좌번호가 복사되었습니다'),
                          ),
                        );
                      },
                      child: const Text('계좌 복사'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      text: '확인',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            const Text('오류'),
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
}