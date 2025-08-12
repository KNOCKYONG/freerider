import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/home/point_card.dart';
import '../../widgets/home/daily_mission_card.dart';
import '../../widgets/home/activity_summary_card.dart';
import '../../widgets/home/quick_action_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Mock data - TODO: Replace with actual data from provider
  final int currentPoints = 850;
  final int targetPoints = AppConstants.dailyTargetPoints;
  final double progress = 850 / 1550;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    // TODO: Implement refresh logic
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryGreen,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            _buildAppBar(),
            
            // Main Content
            SliverPadding(
              padding: AppSpacing.screenPaddingHorizontal,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.md),
                  
                  // Point Card
                  PointCard(
                    currentPoints: currentPoints,
                    targetPoints: targetPoints,
                    progress: progress,
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Quick Actions
                  _buildQuickActions(),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Daily Missions
                  _buildSectionTitle('오늘의 미션'),
                  const SizedBox(height: AppSpacing.md),
                  DailyMissionCard(
                    missions: _getMockMissions(),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Activity Summary
                  _buildSectionTitle('오늘의 활동'),
                  const SizedBox(height: AppSpacing.md),
                  ActivitySummaryCard(
                    activities: _getMockActivities(),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Ad Banner
                  _buildAdBanner(),
                  
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요, 라이더님!',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
              ),
            ),
            Text(
              '오늘도 무료 교통비 받으세요',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.rewardOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            context.go('${context.location}/notification');
          },
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          QuickActionCard(
            icon: Icons.qr_code_scanner_rounded,
            label: 'QR 스캔',
            color: AppColors.subwayBlue,
            onTap: () {
              // TODO: Navigate to QR scanner
            },
          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2, end: 0),
          const SizedBox(width: AppSpacing.sm),
          QuickActionCard(
            icon: Icons.play_circle_fill_rounded,
            label: '광고 보기',
            color: AppColors.rewardOrange,
            onTap: () {
              // TODO: Navigate to ad viewer
            },
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0),
          const SizedBox(width: AppSpacing.sm),
          QuickActionCard(
            icon: Icons.directions_walk_rounded,
            label: '걷기 시작',
            color: AppColors.primaryGreen,
            onTap: () {
              // TODO: Start walking tracker
            },
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2, end: 0),
          const SizedBox(width: AppSpacing.sm),
          QuickActionCard(
            icon: Icons.people_rounded,
            label: '친구 초대',
            color: AppColors.cognitiveColor,
            onTap: () {
              // TODO: Navigate to invite friends
            },
          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigate to detail page
          },
          child: Text(
            '더보기',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdBanner() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: AppColors.rewardGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Open ad
          },
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '광고 보고 100P 받기',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '15초 광고 시청하고 포인트 받으세요',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppSpacing.iconSm,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).shimmer(
      duration: 2000.ms,
      color: Colors.white.withOpacity(0.3),
    );
  }

  List<Mission> _getMockMissions() {
    return [
      Mission(
        id: '1',
        title: '10,000걸음 걷기',
        description: '오늘 10,000걸음을 걸어보세요',
        points: 100,
        progress: 0.65,
        icon: Icons.directions_walk_rounded,
        color: AppColors.movementColor,
      ),
      Mission(
        id: '2',
        title: '광고 5개 시청',
        description: '광고를 시청하고 포인트를 받으세요',
        points: 250,
        progress: 0.4,
        icon: Icons.play_circle_outline_rounded,
        color: AppColors.visualColor,
      ),
      Mission(
        id: '3',
        title: '대중교통 이용',
        description: '대중교통을 이용하면 보너스 포인트',
        points: 50,
        progress: 0,
        icon: Icons.directions_subway_rounded,
        color: AppColors.subwayBlue,
      ),
    ];
  }

  List<Activity> _getMockActivities() {
    return [
      Activity(
        type: '걷기',
        value: '6,543걸음',
        points: 65,
        icon: Icons.directions_walk_rounded,
        color: AppColors.movementColor,
      ),
      Activity(
        type: '계단',
        value: '12층',
        points: 24,
        icon: Icons.stairs_rounded,
        color: AppColors.primaryGreen,
      ),
      Activity(
        type: '광고',
        value: '2개 시청',
        points: 100,
        icon: Icons.play_circle_outline_rounded,
        color: AppColors.visualColor,
      ),
      Activity(
        type: '퀴즈',
        value: '3문제 정답',
        points: 30,
        icon: Icons.quiz_rounded,
        color: AppColors.cognitiveColor,
      ),
    ];
  }
}

// Data models - TODO: Move to proper model files
class Mission {
  final String id;
  final String title;
  final String description;
  final int points;
  final double progress;
  final IconData icon;
  final Color color;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.progress,
    required this.icon,
    required this.color,
  });
}

class Activity {
  final String type;
  final String value;
  final int points;
  final IconData icon;
  final Color color;

  Activity({
    required this.type,
    required this.value,
    required this.points,
    required this.icon,
    required this.color,
  });
}