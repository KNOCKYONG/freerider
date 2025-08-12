import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_router.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/social_login_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // TODO: Implement email login
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      context.go(AppRoutes.main);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    
    // TODO: Implement social login
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      context.go(AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPaddingHorizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              
              // Logo & Title
              _buildHeader(),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              // Social Login Section
              _buildSocialLoginSection(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Divider with "또는"
              _buildDivider(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Email Login Form
              _buildEmailLoginForm(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Login Button
              PrimaryButton(
                text: '로그인',
                onPressed: _isLoading ? null : _handleEmailLogin,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Sign Up Link
              _buildSignUpLink(),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: const Icon(
            Icons.directions_subway_rounded,
            size: 48,
            color: Colors.white,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(delay: 200.ms),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Title
        Text(
          'FREE RIDER',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryGreen,
          ),
        ).animate().fadeIn(delay: 400.ms),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Subtitle
        Text(
          '매일 무료로, 당당하게',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        Text(
          '간편 로그인',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Kakao Login
        SocialLoginButton(
          provider: 'kakao',
          onPressed: () => _handleSocialLogin('kakao'),
          isLoading: _isLoading,
        ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Apple Login
        SocialLoginButton(
          provider: 'apple',
          onPressed: () => _handleSocialLogin('apple'),
          isLoading: _isLoading,
        ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.2, end: 0),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '또는',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildEmailLoginForm() {
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
          ).animate().fadeIn(delay: 1000.ms),
          
          const SizedBox(height: AppSpacing.md),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleEmailLogin(),
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: '8자 이상 입력',
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
          ).animate().fadeIn(delay: 1100.ms),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to forgot password
              },
              child: Text(
                '비밀번호를 잊으셨나요?',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '아직 회원이 아니신가요?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.signup),
          child: Text(
            '회원가입',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}