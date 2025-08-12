import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_router.dart';
import '../../widgets/common/primary_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _agreedToMarketing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms || !_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관에 동의해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // TODO: Implement signup
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      // Navigate to onboarding after signup
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPaddingHorizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              
              // Progress Indicator
              _buildProgressIndicator(),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Title
              Text(
                '프리라이더와 함께\n무료 교통비를 시작하세요',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Form
              _buildSignupForm(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Terms Agreement
              _buildTermsAgreement(),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Signup Button
              PrimaryButton(
                text: '가입하기',
                onPressed: _isLoading ? null : _handleSignup,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: 0.5,
            backgroundColor: AppColors.gray200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryGreen,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'example@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              if (!AppConstants.emailRegex.hasMatch(value)) {
                return '올바른 이메일 형식이 아닙니다';
              }
              return null;
            },
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: AppSpacing.md),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: '8자 이상, 영문/숫자 조합',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해주세요';
              }
              if (value.length < AppConstants.minPasswordLength) {
                return '비밀번호는 ${AppConstants.minPasswordLength}자 이상이어야 합니다';
              }
              return null;
            },
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: AppSpacing.md),
          
          // Password Confirm Field
          TextFormField(
            controller: _passwordConfirmController,
            obscureText: !_isPasswordConfirmVisible,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '비밀번호 확인',
              hintText: '비밀번호를 다시 입력',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordConfirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 다시 입력해주세요';
              }
              if (value != _passwordController.text) {
                return '비밀번호가 일치하지 않습니다';
              }
              return null;
            },
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: AppSpacing.md),
          
          // Nickname Field
          TextFormField(
            controller: _nicknameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '닉네임',
              hintText: '2-12자 한글/영문/숫자',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '닉네임을 입력해주세요';
              }
              if (value.length < AppConstants.nicknameMinLength ||
                  value.length > AppConstants.nicknameMaxLength) {
                return '닉네임은 ${AppConstants.nicknameMinLength}-${AppConstants.nicknameMaxLength}자여야 합니다';
              }
              if (!AppConstants.nicknameRegex.hasMatch(value)) {
                return '한글, 영문, 숫자만 사용 가능합니다';
              }
              return null;
            },
          ).animate().fadeIn(delay: 500.ms),
          
          const SizedBox(height: AppSpacing.md),
          
          // Phone Field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '휴대폰 번호',
              hintText: '010-0000-0000',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '휴대폰 번호를 입력해주세요';
              }
              final cleanPhone = value.replaceAll('-', '');
              if (!AppConstants.phoneRegex.hasMatch(cleanPhone)) {
                return '올바른 휴대폰 번호를 입력해주세요';
              }
              return null;
            },
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildTermsAgreement() {
    return Column(
      children: [
        // All Agree
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: CheckboxListTile(
            title: Text(
              '전체 동의',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            value: _agreedToTerms && _agreedToPrivacy && _agreedToMarketing,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
                _agreedToPrivacy = value ?? false;
                _agreedToMarketing = value ?? false;
              });
            },
            activeColor: AppColors.primaryGreen,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ).animate().fadeIn(delay: 700.ms),
        
        const SizedBox(height: AppSpacing.xs),
        
        // Terms of Service
        CheckboxListTile(
          title: Row(
            children: [
              Text(
                '(필수) ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: Text(
                  '서비스 이용약관 동의',
                  style: AppTypography.bodySmall,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppSpacing.iconSm,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          activeColor: AppColors.primaryGreen,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ).animate().fadeIn(delay: 800.ms),
        
        // Privacy Policy
        CheckboxListTile(
          title: Row(
            children: [
              Text(
                '(필수) ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: Text(
                  '개인정보 처리방침 동의',
                  style: AppTypography.bodySmall,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppSpacing.iconSm,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          value: _agreedToPrivacy,
          onChanged: (value) {
            setState(() {
              _agreedToPrivacy = value ?? false;
            });
          },
          activeColor: AppColors.primaryGreen,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ).animate().fadeIn(delay: 900.ms),
        
        // Marketing Agreement
        CheckboxListTile(
          title: Row(
            children: [
              Text(
                '(선택) ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  '마케팅 정보 수신 동의',
                  style: AppTypography.bodySmall,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppSpacing.iconSm,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          value: _agreedToMarketing,
          onChanged: (value) {
            setState(() {
              _agreedToMarketing = value ?? false;
            });
          },
          activeColor: AppColors.primaryGreen,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ).animate().fadeIn(delay: 1000.ms),
      ],
    );
  }
}