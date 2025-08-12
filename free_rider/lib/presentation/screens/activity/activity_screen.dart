import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/activity_provider.dart';
import '../../../data/models/activity_model.dart';
import '../../widgets/common/primary_button.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _checkPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final activityStatus = await Permission.activityRecognition.status;
    final locationStatus = await Permission.location.status;
    
    if (!activityStatus.isGranted || !locationStatus.isGranted) {
      _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    if (_isRequestingPermission) return;
    
    setState(() => _isRequestingPermission = true);
    
    final permissions = await [
      Permission.activityRecognition,
      Permission.location,
      Permission.sensors,
    ].request();
    
    setState(() => _isRequestingPermission = false);
    
    // Check if all permissions are granted
    final allGranted = permissions.values.every((status) => status.isGranted);
    if (allGranted) {
      ref.read(activityStateProvider.notifier).startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityStateProvider);
    
    // Watch step count stream
    ref.listen(stepCountStreamProvider, (previous, next) {
      next.whenData((stepCount) {
        ref.read(activityStateProvider.notifier).updateSteps(stepCount.steps);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('활동 추적'),
        backgroundColor: AppColors.backgroundPrimary,
        actions: [
          IconButton(
            icon: Icon(
              activityState.isTracking 
                  ? Icons.pause_circle_filled 
                  : Icons.play_circle_filled,
              color: AppColors.primaryGreen,
            ),
            onPressed: () {
              if (activityState.isTracking) {
                ref.read(activityStateProvider.notifier).stopTracking();
              } else {
                ref.read(activityStateProvider.notifier).startTracking();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPaddingHorizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            
            // Main Activity Card
            _buildMainActivityCard(activityState),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Activity Grid
            _buildActivityGrid(activityState),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Recent Activities
            _buildRecentActivities(activityState),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActivityCard(ActivityState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.shadowLg,
      ),
      child: Column(
        children: [
          // Steps Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_walk_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.todaySteps.toString(),
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '걸음',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn().scale(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Progress to 10,000 steps
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '일일 목표',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '${(state.todaySteps / 100).toInt()}P / ${AppConstants.walkingMaxPoints}P',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: (state.todaySteps / 10000).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Tracking Status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isTracking) ...[
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.5 + 0.5 * _animationController.value,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '추적 중',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.pause_circle_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '일시정지',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid(ActivityState state) {
    final activities = [
      ActivitySummary(
        type: '계단',
        displayValue: '${state.todayFloors}층',
        points: state.todayFloors * AppConstants.pointsPerFloor,
        progress: (state.todayFloors / 25).clamp(0.0, 1.0),
        maxPoints: AppConstants.stairsMaxPoints,
      ),
      ActivitySummary(
        type: '자전거',
        displayValue: '${state.cyclingMinutes}분',
        points: state.cyclingMinutes * AppConstants.pointsPerCyclingMinute,
        progress: (state.cyclingMinutes / 60).clamp(0.0, 1.0),
        maxPoints: AppConstants.cyclingMaxPoints,
      ),
      ActivitySummary(
        type: '대중교통',
        displayValue: '${state.transitCount}회',
        points: state.transitCount * AppConstants.pointsPerTransitUse,
        progress: (state.transitCount / 4).clamp(0.0, 1.0),
        maxPoints: AppConstants.transitMaxPoints,
      ),
      ActivitySummary(
        type: '총 포인트',
        displayValue: '${state.totalPoints}P',
        points: state.totalPoints,
        progress: (state.totalPoints / 500).clamp(0.0, 1.0),
        maxPoints: 500,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(ActivitySummary activity) {
    final color = _getActivityColor(activity.type);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activity.type,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(
                _getActivityIcon(activity.type),
                size: AppSpacing.iconSm,
                color: color,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.displayValue,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: activity.progress,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * activities.indexOf(activity)));
  }

  Widget _buildRecentActivities(ActivityState state) {
    if (state.activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Icon(
              Icons.directions_walk_rounded,
              size: 48,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '오늘의 활동을 시작해보세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 활동',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...state.activities.reversed.take(5).map((activity) {
          return _buildActivityItem(activity);
        }).toList(),
      ],
    );
  }

  Widget _buildActivityItem(DailyActivity activity) {
    final icon = _getActivityTypeIcon(activity.type);
    final color = _getActivityTypeColor(activity.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActivityTypeName(activity.type),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${activity.value} ${_getActivityUnit(activity.type)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${activity.points}P',
                style: AppTypography.titleSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatTime(activity.timestamp),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case '계단': return AppColors.primaryGreen;
      case '자전거': return AppColors.subwayBlue;
      case '대중교통': return AppColors.rewardOrange;
      case '총 포인트': return AppColors.primaryGreen;
      default: return AppColors.gray500;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case '계단': return Icons.stairs_rounded;
      case '자전거': return Icons.directions_bike_rounded;
      case '대중교통': return Icons.directions_subway_rounded;
      case '총 포인트': return Icons.stars_rounded;
      default: return Icons.directions_walk_rounded;
    }
  }

  IconData _getActivityTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.walking: return Icons.directions_walk_rounded;
      case ActivityType.stairs: return Icons.stairs_rounded;
      case ActivityType.cycling: return Icons.directions_bike_rounded;
      case ActivityType.transit: return Icons.directions_subway_rounded;
      case ActivityType.running: return Icons.directions_run_rounded;
      default: return Icons.fitness_center_rounded;
    }
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.walking: return AppColors.movementColor;
      case ActivityType.stairs: return AppColors.primaryGreen;
      case ActivityType.cycling: return AppColors.subwayBlue;
      case ActivityType.transit: return AppColors.rewardOrange;
      default: return AppColors.gray500;
    }
  }

  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.walking: return '걷기';
      case ActivityType.stairs: return '계단 오르기';
      case ActivityType.cycling: return '자전거';
      case ActivityType.transit: return '대중교통';
      case ActivityType.running: return '러닝';
      default: return '활동';
    }
  }

  String _getActivityUnit(ActivityType type) {
    switch (type) {
      case ActivityType.walking: return '걸음';
      case ActivityType.stairs: return '층';
      case ActivityType.cycling: return '분';
      case ActivityType.transit: return '회';
      case ActivityType.running: return '분';
      default: return '';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}