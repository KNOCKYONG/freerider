import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/ai/data_labeling_service.dart';
import '../../../data/providers/points_provider.dart';
import 'ai_labeling_task_screen.dart';

class AILabelingScreen extends ConsumerStatefulWidget {
  const AILabelingScreen({super.key});

  @override
  ConsumerState<AILabelingScreen> createState() => _AILabelingScreenState();
}

class _AILabelingScreenState extends ConsumerState<AILabelingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataLabelingService _labelingService = DataLabelingService();
  
  List<LabelingTask> _availableTasks = [];
  UserLabelingStats? _userStats;
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;
  
  // 필터
  TaskCategory? _selectedCategory;
  TaskDifficulty? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _labelingService.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final tasks = await _labelingService.getAvailableTasks(
        userId: 'user_001',
        difficulty: _selectedDifficulty,
        category: _selectedCategory,
      );
      final stats = _labelingService.getUserStats('user_001');
      final leaderboard = _labelingService.getLeaderboard();
      
      setState(() {
        _availableTasks = tasks;
        _userStats = stats;
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('AI 데이터 라벨링'),
        backgroundColor: AppColors.backgroundPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: '작업'),
            Tab(text: '내 정보'),
            Tab(text: '랭킹'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksTab(),
          _buildMyInfoTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // 필터 바
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 카테고리 필터
                _buildFilterChip('전체', null, isCategory: true),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('이미지', TaskCategory.imageClassification, isCategory: true),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('텍스트', TaskCategory.textClassification, isCategory: true),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('음성', TaskCategory.audioTranscription, isCategory: true),
                const SizedBox(width: AppSpacing.md),
                
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.border,
                ),
                const SizedBox(width: AppSpacing.md),
                
                // 난이도 필터
                _buildFilterChip('쉬움', TaskDifficulty.easy, isCategory: false),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('보통', TaskDifficulty.medium, isCategory: false),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('어려움', TaskDifficulty.hard, isCategory: false),
              ],
            ),
          ),
        ),
        
        // 작업 목록
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: AppSpacing.screenPaddingHorizontal,
              itemCount: _availableTasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(_availableTasks[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyInfoTab() {
    if (_userStats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // 레벨 카드
          _buildLevelCard(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 통계
          Text(
            '작업 통계',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildStatsGrid(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 품질 분석
          Text(
            '품질 분석',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildQualityCard(),
          
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView.builder(
      padding: AppSpacing.screenPaddingHorizontal,
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        return _buildLeaderboardCard(_leaderboard[index], index + 1);
      },
    );
  }

  Widget _buildTaskCard(LabelingTask task) {
    final categoryInfo = _getCategoryInfo(task.category);
    final difficultyInfo = _getDifficultyInfo(task.difficulty);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 아이콘
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      categoryInfo.icon,
                      color: categoryInfo.color,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // 제목과 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            // 레벨 요구사항
                            if (task.requiredLevel > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                ),
                                child: Text(
                                  'Lv.${task.requiredLevel}+',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (task.requiredLevel > 1) const SizedBox(width: AppSpacing.xs),
                            
                            // 난이도
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: difficultyInfo.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                              child: Text(
                                difficultyInfo.label,
                                style: AppTypography.labelSmall.copyWith(
                                  color: difficultyInfo.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 포인트
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${task.pointsPerItem}',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'P/건',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // 설명
              Text(
                task.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // 진행률과 시간
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '남은 작업: ${task.remainingCount}/${task.totalItems}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      LinearProgressIndicator(
                        value: (task.totalItems - task.remainingCount) / task.totalItems,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '${task.estimatedTimePerItem}초/건',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDeadline(task.deadline),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildLevelCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cognitiveColor,
            AppColors.cognitiveColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppSpacing.shadowMd,
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
                    'Level ${_userStats!.level}',
                    style: AppTypography.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'AI 데이터 라벨러',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '다음 레벨까지',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: _userStats!.nextLevelProgress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${(_userStats!.nextLevelProgress * 100).toInt()}%',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '완료 작업',
          '${_userStats!.totalSubmissions}건',
          Icons.task_alt_rounded,
          AppColors.success,
        ),
        _buildStatCard(
          '획득 포인트',
          '${_userStats!.totalPoints}P',
          Icons.stars_rounded,
          AppColors.rewardOrange,
        ),
        _buildStatCard(
          '평균 품질',
          '${(_userStats!.averageQuality * 100).toInt()}점',
          Icons.thumb_up_rounded,
          AppColors.primaryGreen,
        ),
        _buildStatCard(
          '정확도',
          '${(_userStats!.averageQuality * 100).toInt()}%',
          Icons.speed_rounded,
          AppColors.subwayBlue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard() {
    final qualityScore = _userStats!.averageQuality;
    Color qualityColor;
    String qualityLabel;
    
    if (qualityScore >= 0.9) {
      qualityColor = AppColors.success;
      qualityLabel = '우수';
    } else if (qualityScore >= 0.8) {
      qualityColor = AppColors.primaryGreen;
      qualityLabel = '양호';
    } else if (qualityScore >= 0.7) {
      qualityColor = AppColors.warning;
      qualityLabel = '보통';
    } else {
      qualityColor = AppColors.error;
      qualityLabel = '개선필요';
    }
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '품질 점수',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: qualityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  qualityLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: qualityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: qualityScore,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${(qualityScore * 100).toInt()}/100점',
            style: AppTypography.bodyLarge.copyWith(
              color: qualityColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '품질 점수가 높을수록 더 많은 보너스 포인트를 받을 수 있습니다.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int rank) {
    Color rankColor;
    IconData rankIcon;
    
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.emoji_events_rounded;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.emoji_events_rounded;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.emoji_events_rounded;
        break;
      default:
        rankColor = AppColors.textSecondary;
        rankIcon = Icons.person_rounded;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: rank <= 3 ? rankColor.withOpacity(0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: rank <= 3 ? rankColor.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // 순위
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      rankIcon,
                      color: rankColor,
                      size: 20,
                    )
                  : Text(
                      '$rank',
                      style: AppTypography.titleMedium.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Text(
                      '완료 ${entry.submissions}건',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '품질 ${(entry.averageQuality * 100).toInt()}점',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 포인트
          Text(
            '${entry.points}P',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, dynamic value, {required bool isCategory}) {
    final isSelected = isCategory
        ? _selectedCategory == value
        : _selectedDifficulty == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (isCategory) {
            _selectedCategory = selected ? value : null;
          } else {
            _selectedDifficulty = selected ? value : null;
          }
        });
        _loadData();
      },
      selectedColor: AppColors.primaryGreen.withOpacity(0.2),
      backgroundColor: AppColors.gray100,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryGreen : AppColors.gray200,
      ),
    );
  }

  void _showTaskDetail(LabelingTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _buildTaskDetailSheet(
          task,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildTaskDetailSheet(
    LabelingTask task,
    ScrollController scrollController,
  ) {
    final categoryInfo = _getCategoryInfo(task.category);
    final examples = _labelingService.getTaskExamples(task.id);
    
    return Column(
      children: [
        // 핸들
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: AppSpacing.screenPaddingHorizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                
                // 헤더
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: categoryInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        categoryInfo.icon,
                        color: categoryInfo.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${task.pointsPerItem}P/건 • ${task.estimatedTimePerItem}초',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 설명
                Text(
                  '작업 설명',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  task.description,
                  style: AppTypography.bodyMedium,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 지시사항
                Text(
                  '작업 지시사항',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...task.instructions.map((instruction) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          instruction,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
                
                if (examples.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  
                  // 예시
                  Text(
                    '작업 예시',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...examples.map((example) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '입력:',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          example.input,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '예상 출력:',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          example.expectedOutput.toString(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        if (example.explanation.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '설명: ${example.explanation}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
                ],
                
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
        
        // 버튼
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
          child: ElevatedButton(
            onPressed: () => _startTask(task),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '작업 시작하기',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startTask(LabelingTask task) async {
    Navigator.pop(context);
    
    // 작업 세션 시작
    final session = await _labelingService.startTask(
      userId: 'user_001',
      taskId: task.id,
    );
    
    // 작업 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AILabelingTaskScreen(
          session: session,
          task: task,
        ),
      ),
    ).then((_) {
      // 작업 완료 후 데이터 새로고침
      _loadData();
    });
  }

  _CategoryInfo _getCategoryInfo(TaskCategory category) {
    switch (category) {
      case TaskCategory.imageClassification:
        return _CategoryInfo(
          label: '이미지 분류',
          icon: Icons.image_rounded,
          color: AppColors.visualColor,
        );
      case TaskCategory.objectDetection:
        return _CategoryInfo(
          label: '객체 탐지',
          icon: Icons.center_focus_strong_rounded,
          color: AppColors.subwayBlue,
        );
      case TaskCategory.textClassification:
        return _CategoryInfo(
          label: '텍스트 분류',
          icon: Icons.text_fields_rounded,
          color: AppColors.cognitiveColor,
        );
      case TaskCategory.textSummarization:
        return _CategoryInfo(
          label: '텍스트 요약',
          icon: Icons.summarize_rounded,
          color: AppColors.primaryGreen,
        );
      case TaskCategory.audioTranscription:
        return _CategoryInfo(
          label: '음성 전사',
          icon: Icons.mic_rounded,
          color: AppColors.voiceColor,
        );
      case TaskCategory.videoAnnotation:
        return _CategoryInfo(
          label: '동영상 주석',
          icon: Icons.video_label_rounded,
          color: AppColors.movementColor,
        );
      case TaskCategory.dataCategorization:
        return _CategoryInfo(
          label: '데이터 분류',
          icon: Icons.category_rounded,
          color: AppColors.rewardOrange,
        );
    }
  }

  _DifficultyInfo _getDifficultyInfo(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return _DifficultyInfo(
          label: '쉬움',
          color: AppColors.success,
        );
      case TaskDifficulty.medium:
        return _DifficultyInfo(
          label: '보통',
          color: AppColors.warning,
        );
      case TaskDifficulty.hard:
        return _DifficultyInfo(
          label: '어려움',
          color: AppColors.error,
        );
      case TaskDifficulty.expert:
        return _DifficultyInfo(
          label: '전문가',
          color: AppColors.cognitiveColor,
        );
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    
    if (diff.inDays > 0) {
      return 'D-${diff.inDays}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 남음';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 남음';
    } else {
      return '마감';
    }
  }
}

class _CategoryInfo {
  final String label;
  final IconData icon;
  final Color color;

  _CategoryInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _DifficultyInfo {
  final String label;
  final Color color;

  _DifficultyInfo({
    required this.label,
    required this.color,
  });
}