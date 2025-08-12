import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/survey_provider.dart';
import '../../../data/models/survey_model.dart';
import '../../widgets/common/primary_button.dart';

class SurveyScreen extends ConsumerStatefulWidget {
  final String surveyId;
  
  const SurveyScreen({super.key, required this.surveyId});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_pageController.page!.toInt() < _getSurvey()!.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitSurvey();
    }
  }

  void _previousQuestion() {
    if (_pageController.page!.toInt() > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Survey? _getSurvey() {
    return ref.watch(surveyProvider(widget.surveyId));
  }

  Future<void> _submitSurvey() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final result = await ref.read(surveyStateProvider.notifier)
          .submitSurvey(widget.surveyId, _answers);
      
      if (result && mounted) {
        _showCompletionDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showCompletionDialog() {
    final survey = _getSurvey();
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
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ).animate().scale(),
              const SizedBox(height: AppSpacing.md),
              Text(
                '설문 완료!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${survey?.points ?? 0}P 획듍',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
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

  @override
  Widget build(BuildContext context) {
    final survey = _getSurvey();
    
    if (survey == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(survey.title),
        backgroundColor: AppColors.backgroundPrimary,
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / survey.questions.length,
              backgroundColor: AppColors.gray200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Question Number
          Text(
            '질문 ${_currentPage + 1} / ${survey.questions.length}',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              itemCount: survey.questions.length,
              itemBuilder: (context, index) {
                final question = survey.questions[index];
                return _buildQuestion(question, index);
              },
            ),
          ),
          
          // Navigation Buttons
          Padding(
            padding: AppSpacing.screenPaddingHorizontal,
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: const Text('이전'),
                    ),
                  ),
                if (_currentPage > 0)
                  const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    text: _currentPage == survey.questions.length - 1
                        ? '제출'
                        : '다음',
                    onPressed: _answers[_currentPage] != null
                        ? _nextQuestion
                        : null,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildQuestion(SurveyQuestion question, int index) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // Question Text
          Text(
            question.text,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn().slideX(begin: 0.1),
          
          if (question.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              question.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          
          const SizedBox(height: AppSpacing.xl),
          
          // Answer Options
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            
            return _buildOption(
              option,
              index,
              optionIndex,
              question.type,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOption(
    SurveyOption option,
    int questionIndex,
    int optionIndex,
    QuestionType type,
  ) {
    final isSelected = type == QuestionType.single
        ? _answers[questionIndex] == optionIndex
        : (_answers[questionIndex] as List<int>?)?.contains(optionIndex) ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          setState(() {
            if (type == QuestionType.single) {
              _answers[questionIndex] = optionIndex;
            } else {
              final currentAnswers = _answers[questionIndex] as List<int>? ?? [];
              if (currentAnswers.contains(optionIndex)) {
                currentAnswers.remove(optionIndex);
              } else {
                currentAnswers.add(optionIndex);
              }
              _answers[questionIndex] = currentAnswers;
            }
          });
        },
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
              Icon(
                type == QuestionType.single
                    ? (isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked)
                    : (isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank),
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.text,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 50 * optionIndex))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }
}