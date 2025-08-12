import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/points_provider.dart';
import '../../widgets/common/primary_button.dart';

/// 인터랙티브 광고 화면
/// 설문형, 미니게임형 광고로 높은 포인트 제공
class InteractiveAdScreen extends ConsumerStatefulWidget {
  final String adId;
  final InteractiveAdType type;
  
  const InteractiveAdScreen({
    super.key,
    required this.adId,
    required this.type,
  });

  @override
  ConsumerState<InteractiveAdScreen> createState() => _InteractiveAdScreenState();
}

class _InteractiveAdScreenState extends ConsumerState<InteractiveAdScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _successController;
  
  // 설문형 광고 상태
  int _currentQuestionIndex = 0;
  final Map<int, dynamic> _surveyAnswers = {};
  
  // 미니게임형 광고 상태
  int _gameScore = 0;
  Timer? _gameTimer;
  int _gameTimeLeft = 30;
  bool _isGameActive = false;
  
  // 공통 상태
  bool _isCompleted = false;
  int _earnedPoints = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    if (widget.type == InteractiveAdType.miniGame) {
      _startGame();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _gameScore = 0;
      _gameTimeLeft = 30;
    });
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameTimeLeft > 0) {
        setState(() => _gameTimeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _isGameActive = false;
      _isCompleted = true;
      // 점수에 따른 포인트 계산 (최대 200P)
      _earnedPoints = min(200, 50 + (_gameScore * 10));
    });
    _successController.forward();
    
    // 포인트 지급
    ref.read(pointsStateProvider.notifier).addPoints(
      _earnedPoints,
      '인터랙티브 광고 완료',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          widget.type == InteractiveAdType.survey 
              ? '설문 광고' 
              : '미니게임 광고',
        ),
        backgroundColor: AppColors.backgroundPrimary,
      ),
      body: _isCompleted
          ? _buildCompletionScreen()
          : widget.type == InteractiveAdType.survey
              ? _buildSurveyContent()
              : _buildMiniGameContent(),
    );
  }

  Widget _buildSurveyContent() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // 진행률 표시
          _buildProgressIndicator(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 질문 카드
          _buildQuestionCard(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 답변 옵션
          _buildAnswerOptions(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 다음 버튼
          if (_surveyAnswers.containsKey(_currentQuestionIndex))
            PrimaryButton(
              text: _currentQuestionIndex < _surveyQuestions.length - 1
                  ? '다음 질문'
                  : '완료',
              onPressed: _nextQuestion,
            ),
        ],
      ),
    );
  }

  Widget _buildMiniGameContent() {
    return Stack(
      children: [
        // 게임 배경
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryGreen.withOpacity(0.1),
                AppColors.backgroundPrimary,
              ],
            ),
          ),
        ),
        
        // 게임 UI
        SafeArea(
          child: Padding(
            padding: AppSpacing.screenPaddingHorizontal,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                
                // 게임 헤더 (시간, 점수)
                _buildGameHeader(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // 게임 플레이 영역
                Expanded(
                  child: _buildGamePlayArea(),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // 게임 설명
                _buildGameInstructions(),
                
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentQuestionIndex + 1) / _surveyQuestions.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '질문 ${_currentQuestionIndex + 1} / ${_surveyQuestions.length}',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final question = _surveyQuestions[_currentQuestionIndex];
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              question['category'],
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            question['question'],
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (question['description'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              question['description'],
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildAnswerOptions() {
    final question = _surveyQuestions[_currentQuestionIndex];
    final options = question['options'] as List<String>;
    final selectedAnswer = _surveyAnswers[_currentQuestionIndex];
    
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedAnswer == index;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: () => _selectAnswer(index),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryGreen.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primaryGreen
                      : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected 
                          ? AppColors.primaryGreen
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primaryGreen
                            : AppColors.gray400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected 
                            ? AppColors.primaryGreen
                            : AppColors.textPrimary,
                        fontWeight: isSelected 
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: index * 50))
              .fadeIn()
              .slideX(begin: -0.1, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildGameHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 시간
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _gameTimeLeft <= 10 
                ? AppColors.error.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: _gameTimeLeft <= 10 
                  ? AppColors.error
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: _gameTimeLeft <= 10 
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${_gameTimeLeft}초',
                style: AppTypography.bodyMedium.copyWith(
                  color: _gameTimeLeft <= 10 
                      ? AppColors.error
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // 점수
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.primaryGreen),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 20,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$_gameScore점',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamePlayArea() {
    return GestureDetector(
      onTapDown: _isGameActive ? _handleGameTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            // 게임 오브젝트들
            ..._generateGameObjects(),
            
            // 중앙 안내 메시지
            if (!_isGameActive && !_isCompleted)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 64,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '화면을 터치하여 시작',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateGameObjects() {
    final random = Random();
    final objects = <Widget>[];
    
    if (_isGameActive) {
      for (int i = 0; i < 5; i++) {
        objects.add(
          Positioned(
            left: random.nextDouble() * 300,
            top: random.nextDouble() * 400,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1 - value,
                  child: Opacity(
                    opacity: 1 - value,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                );
              },
              onEnd: () {
                setState(() {}); // 재생성
              },
            ),
          ),
        );
      }
    }
    
    return objects;
  }

  Widget _buildGameInstructions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '별을 터치하여 점수를 획득하세요! 높은 점수일수록 더 많은 포인트!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingHorizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 60,
                color: AppColors.primaryGreen,
              ),
            ).animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              '광고 완료!',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            Text(
              '${_earnedPoints}P 획득',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w800,
              ),
            ).animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: AppSpacing.xs),
            
            Text(
              widget.type == InteractiveAdType.miniGame
                  ? '게임 점수: $_gameScore점'
                  : '설문 참여 감사합니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            PrimaryButton(
              text: '확인',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      _surveyAnswers[_currentQuestionIndex] = index;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _surveyQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _animationController.forward(from: 0);
    } else {
      // 설문 완료
      setState(() {
        _isCompleted = true;
        _earnedPoints = 150; // 설문 완료 보상
      });
      _successController.forward();
      
      // 포인트 지급
      ref.read(pointsStateProvider.notifier).addPoints(
        _earnedPoints,
        '설문 광고 완료',
      );
    }
  }

  void _handleGameTap(TapDownDetails details) {
    if (_isGameActive) {
      setState(() {
        _gameScore++;
      });
      
      // 터치 효과 애니메이션
      _animationController.forward(from: 0);
    }
  }

  // Mock 설문 데이터
  final List<Map<String, dynamic>> _surveyQuestions = [
    {
      'category': '라이프스타일',
      'question': '평소 출퇴근 시 주로 이용하는 교통수단은?',
      'options': [
        '지하철',
        '버스',
        '자가용',
        '자전거/킥보드',
        '도보',
      ],
    },
    {
      'category': '쇼핑',
      'question': '온라인 쇼핑을 주로 이용하는 시간대는?',
      'description': '가장 자주 이용하는 시간대를 선택해주세요',
      'options': [
        '오전 (6시-12시)',
        '오후 (12시-18시)',
        '저녁 (18시-22시)',
        '심야 (22시-6시)',
      ],
    },
    {
      'category': '브랜드',
      'question': '다음 중 가장 선호하는 커피 브랜드는?',
      'options': [
        '스타벅스',
        '투썸플레이스',
        '이디야',
        '메가커피',
        '컴포즈커피',
      ],
    },
  ];
}

/// 인터랙티브 광고 타입
enum InteractiveAdType {
  survey,    // 설문형
  miniGame,  // 미니게임형
  quiz,      // 퀴즈형
}