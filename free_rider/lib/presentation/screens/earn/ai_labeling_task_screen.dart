import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/ai/data_labeling_service.dart';
import '../../../data/providers/points_provider.dart';

class AILabelingTaskScreen extends ConsumerStatefulWidget {
  final LabelingSession session;
  final LabelingTask task;

  const AILabelingTaskScreen({
    super.key,
    required this.session,
    required this.task,
  });

  @override
  ConsumerState<AILabelingTaskScreen> createState() => _AILabelingTaskScreenState();
}

class _AILabelingTaskScreenState extends ConsumerState<AILabelingTaskScreen> {
  final DataLabelingService _labelingService = DataLabelingService();
  
  late DateTime _taskStartTime;
  int _currentItemIndex = 0;
  final Map<String, dynamic> _currentLabelData = {};
  bool _isSubmitting = false;
  int _completedItems = 0;
  int _totalPointsEarned = 0;
  
  // 작업별 UI 상태
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _taskStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.session.items[_currentItemIndex];
    
    return WillPopScope(
      onWillPop: () => _showExitDialog(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          title: Text(widget.task.title),
          backgroundColor: AppColors.backgroundPrimary,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _showExitDialog(),
          ),
          actions: [
            // 진행률 표시
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              margin: const EdgeInsets.only(right: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '${_currentItemIndex + 1}/${widget.session.items.length}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // 진행률 바
            LinearProgressIndicator(
              value: (_currentItemIndex + 1) / widget.session.items.length,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
            
            // 작업 영역
            Expanded(
              child: _buildTaskContent(currentItem),
            ),
            
            // 하단 버튼 영역
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: _buildBottomButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskContent(LabelingItem item) {
    switch (widget.task.category) {
      case TaskCategory.imageClassification:
        return _buildImageClassificationTask(item);
      case TaskCategory.textClassification:
        return _buildTextClassificationTask(item);
      case TaskCategory.audioTranscription:
        return _buildAudioTranscriptionTask(item);
      case TaskCategory.textSummarization:
        return _buildTextSummarizationTask(item);
      default:
        return _buildGenericTask(item);
    }
  }

  Widget _buildImageClassificationTask(LabelingItem item) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // 이미지
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_rounded,
                    size: 64,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '이미지 로딩중...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.content,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 분류 옵션
          Text(
            '이미지 속 주요 동물을 선택해주세요',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ...['고양이', '개', '새', '물고기', '기타', '동물 없음'].map((label) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RadioListTile<String>(
                title: Text(label),
                value: label,
                groupValue: _currentLabelData['label'] as String?,
                onChanged: (value) {
                  setState(() {
                    _currentLabelData['label'] = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
            );
          }),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 확신도
          Text(
            '확신도를 선택해주세요',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ...['매우 확실', '확실', '보통', '불확실'].map((confidence) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RadioListTile<String>(
                title: Text(confidence),
                value: confidence,
                groupValue: _currentLabelData['confidence'] as String?,
                onChanged: (value) {
                  setState(() {
                    _currentLabelData['confidence'] = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
            );
          }),
          
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildTextClassificationTask(LabelingItem item) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // 텍스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '분석할 텍스트',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.content,
                  style: AppTypography.bodyLarge,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 감정 분류
          Text(
            '텍스트의 전반적인 감정을 선택해주세요',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ...['매우 긍정', '긍정', '중립', '부정', '매우 부정'].map((sentiment) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Text(sentiment),
                    const SizedBox(width: AppSpacing.sm),
                    _getSentimentIcon(sentiment),
                  ],
                ),
                value: sentiment,
                groupValue: _currentLabelData['sentiment'] as String?,
                onChanged: (value) {
                  setState(() {
                    _currentLabelData['sentiment'] = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
            );
          }),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 감정 강도
          Text(
            '감정의 강도 (0.0 ~ 1.0)',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Slider(
            value: (_currentLabelData['intensity'] as double?) ?? 0.5,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: (_currentLabelData['intensity'] as double?)?.toStringAsFixed(1) ?? '0.5',
            onChanged: (value) {
              setState(() {
                _currentLabelData['intensity'] = value;
              });
            },
            activeColor: AppColors.primaryGreen,
          ),
          
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildAudioTranscriptionTask(LabelingItem item) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // 오디오 플레이어
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.audio_file_rounded,
                  size: 64,
                  color: AppColors.voiceColor,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '오디오 파일',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${item.metadata['duration'] ?? 0}초',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Mock 재생/정지
                      },
                      icon: Icon(
                        Icons.play_arrow_rounded,
                        size: 32,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 전사 텍스트
          Text(
            '음성을 들어보시고 정확한 텍스트로 전사해주세요',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '음성 내용을 정확한 맞춤법으로 입력해주세요...',
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
              _currentLabelData['transcription'] = value;
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 불명확 구간 체크
          CheckboxListTile(
            title: const Text('불명확한 구간이 있습니다'),
            value: _currentLabelData['hasUnclearParts'] as bool? ?? false,
            onChanged: (value) {
              setState(() {
                _currentLabelData['hasUnclearParts'] = value ?? false;
              });
            },
            activeColor: AppColors.primaryGreen,
          ),
          
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildTextSummarizationTask(LabelingItem item) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // 원본 텍스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '요약할 텍스트',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Text(
                      item.content,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 요약 작성
          Text(
            '핵심 내용을 3줄 이내로 요약해주세요',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '• 첫 번째 핵심 내용\n• 두 번째 핵심 내용\n• 세 번째 핵심 내용',
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
              _currentLabelData['summary'] = value;
            },
          ),
          
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildGenericTask(LabelingItem item) {
    return Center(
      child: Text(
        '이 작업 타입은 아직 지원되지 않습니다.',
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isDataValid = _validateCurrentData();
    
    return Row(
      children: [
        // 건너뛰기
        if (_currentItemIndex > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _previousItem,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                side: BorderSide(color: AppColors.textSecondary),
              ),
              child: Text(
                '이전',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        
        if (_currentItemIndex > 0) const SizedBox(width: AppSpacing.md),
        
        // 제출/다음
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: (_isSubmitting || !isDataValid) ? null : _submitCurrentItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentItemIndex == widget.session.items.length - 1
                            ? '작업 완료'
                            : '제출하고 다음',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        _currentItemIndex == widget.session.items.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  bool _validateCurrentData() {
    switch (widget.task.category) {
      case TaskCategory.imageClassification:
        return _currentLabelData['label'] != null &&
               _currentLabelData['confidence'] != null;
      case TaskCategory.textClassification:
        return _currentLabelData['sentiment'] != null &&
               _currentLabelData['intensity'] != null;
      case TaskCategory.audioTranscription:
        return (_currentLabelData['transcription'] as String?)?.isNotEmpty == true;
      case TaskCategory.textSummarization:
        return (_currentLabelData['summary'] as String?)?.isNotEmpty == true;
      default:
        return true;
    }
  }

  Future<void> _submitCurrentItem() async {
    if (!_validateCurrentData()) return;
    
    setState(() => _isSubmitting = true);
    
    final timeSpent = DateTime.now().difference(_taskStartTime).inSeconds;
    final currentItem = widget.session.items[_currentItemIndex];
    
    try {
      final result = await _labelingService.submitLabeling(
        sessionId: widget.session.id,
        itemId: currentItem.id,
        labelData: Map<String, dynamic>.from(_currentLabelData),
        timeSpentSeconds: timeSpent,
      );
      
      if (result.success) {
        // 포인트 추가
        ref.read(pointsStateProvider.notifier).addPoints(
          result.points ?? 0,
          '데이터 라벨링',
        );
        
        _completedItems++;
        _totalPointsEarned += result.points ?? 0;
        
        // 성공 애니메이션
        _showSuccessAnimation(result.points ?? 0);
        
        // 다음 아이템으로
        if (_currentItemIndex < widget.session.items.length - 1) {
          _nextItem();
        } else {
          _completeSession();
        }
      } else {
        _showErrorDialog(result.error ?? '제출 실패');
      }
    } catch (e) {
      _showErrorDialog('네트워크 오류: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _nextItem() {
    setState(() {
      _currentItemIndex++;
      _currentLabelData.clear();
      _taskStartTime = DateTime.now();
    });
  }

  void _previousItem() {
    setState(() {
      _currentItemIndex--;
      _currentLabelData.clear();
      _taskStartTime = DateTime.now();
    });
  }

  void _showSuccessAnimation(int points) {
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
              Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.success,
              ).animate().scale(duration: 300.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                '+${points}P',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '작업 완료!',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
    
    // 1초 후 자동 닫기
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _completeSession() {
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
            Icon(Icons.celebration_rounded, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            const Text('세션 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('모든 작업을 완료했습니다.'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('완료한 작업:'),
                      Text('${_completedItems}건'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('총 획득 포인트:'),
                      Text(
                        '${_totalPointsEarned}P',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 작업 화면 닫기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.error_rounded, color: AppColors.error),
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

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('작업을 종료하시겠습니까?'),
        content: const Text('지금까지 진행한 내용이 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '종료',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case '매우 긍정':
        return Icon(Icons.sentiment_very_satisfied_rounded, color: AppColors.success, size: 20);
      case '긍정':
        return Icon(Icons.sentiment_satisfied_rounded, color: AppColors.success, size: 20);
      case '중립':
        return Icon(Icons.sentiment_neutral_rounded, color: AppColors.textSecondary, size: 20);
      case '부정':
        return Icon(Icons.sentiment_dissatisfied_rounded, color: AppColors.warning, size: 20);
      case '매우 부정':
        return Icon(Icons.sentiment_very_dissatisfied_rounded, color: AppColors.error, size: 20);
      default:
        return const SizedBox.shrink();
    }
  }
}