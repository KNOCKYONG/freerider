import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/friends_provider.dart';
import '../../../data/models/friend_model.dart';
import '../../widgets/common/primary_button.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _shareInviteCode() {
    final state = ref.read(friendsStateProvider);
    final message = '🚀 FREERIDER에서 하루 1,550원 무료 교통비 받으세요!\n\n'
        '제 초대코드: ${state.myInviteCode}\n\n'
        '앱 다운로드: https://freerider.app/invite/${state.myInviteCode}';
    
    Share.share(message, subject: 'FREERIDER 초대');
  }

  void _copyInviteCode() {
    final state = ref.read(friendsStateProvider);
    Clipboard.setData(ClipboardData(text: state.myInviteCode));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('초대 코드가 복사되었습니다'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enterInviteCode() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;
    
    final result = await ref.read(friendsStateProvider.notifier)
        .enterInviteCode(code);
    
    if (result && mounted) {
      _inviteCodeController.clear();
      _showSuccessDialog();
    } else if (mounted) {
      _showErrorDialog('유효하지 않거나 이미 사용된 코드입니다');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
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
                  Icons.people_rounded,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ).animate().scale(),
              const SizedBox(height: AppSpacing.md),
              Text(
                '초대 성공!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+100P 보너스 획듍',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: '확인',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('초대 코드 오류'),
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

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsStateProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('친구'),
        backgroundColor: AppColors.backgroundPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          tabs: [
            Tab(text: '내 친구'),
            Tab(text: '초대하기'),
            Tab(text: '리더보드'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(friendsState),
          _buildInviteTab(friendsState),
          _buildLeaderboardTab(friendsState),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(FriendsState state) {
    if (state.friends.isEmpty) {
      return _buildEmptyFriends();
    }
    
    return ListView.builder(
      padding: AppSpacing.screenPaddingHorizontal,
      itemCount: state.friends.length,
      itemBuilder: (context, index) {
        final friend = state.friends[index];
        return _buildFriendCard(friend, index);
      },
    );
  }

  Widget _buildEmptyFriends() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: AppColors.gray300,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '아직 친구가 없어요',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '친구를 초대하고 함께 포인트를 모아보세요!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: '친구 초대하기',
            onPressed: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Friend friend, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                friend.nickname.substring(0, 1).toUpperCase(),
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.nickname,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '오늘 ${friend.todayPoints}P 획듍',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Ranking
          if (friend.ranking != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _getRankingColor(friend.ranking!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '#${friend.ranking}',
                style: AppTypography.labelMedium.copyWith(
                  color: _getRankingColor(friend.ranking!),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn()
        .slideX(begin: 0.1);
  }

  Widget _buildInviteTab(FriendsState state) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // My Invite Code
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppSpacing.shadowLg,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '내 초대 코드',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    state.myInviteCode,
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyInviteCode,
                        icon: const Icon(Icons.copy, size: 20),
                        label: const Text('복사'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareInviteCode,
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('공유'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Invite Benefits
          _buildInviteBenefits(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Enter Friend's Code
          _buildEnterCodeSection(),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildInviteBenefits() {
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
            children: [
              Icon(
                Icons.celebration_rounded,
                color: AppColors.rewardOrange,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '초대 혜택',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBenefitItem('• 친구가 가입하면 100P 즉시 지급'),
          _buildBenefitItem('• 친구가 첫 충전 성공 시 500P 추가'),
          _buildBenefitItem('• 친구와 함께 챌린지 참여 가능'),
          _buildBenefitItem('• 최대 10명까지 초대 가능'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildEnterCodeSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '친구 코드 입력',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                text: '등록',
                onPressed: _enterInviteCode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(FriendsState state) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              indicatorColor: AppColors.primaryGreen,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: '일간'),
                Tab(text: '주간'),
                Tab(text: '월간'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLeaderboardList(state.dailyLeaderboard),
                _buildLeaderboardList(state.weeklyLeaderboard),
                _buildLeaderboardList(state.monthlyLeaderboard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('리더보드가 없습니다'),
      );
    }
    
    return ListView.builder(
      padding: AppSpacing.screenPaddingHorizontal,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildLeaderboardItem(entry, index + 1);
      },
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int rank) {
    final isMe = entry.userId == 'current_user'; // 실제로는 현재 사용자 ID
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primaryGreen.withOpacity(0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isMe ? AppColors.primaryGreen : AppColors.border,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankingColor(rank).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      rank == 1 ? Icons.looks_one
                          : rank == 2 ? Icons.looks_two
                          : Icons.looks_3,
                      color: _getRankingColor(rank),
                      size: 24,
                    )
                  : Text(
                      rank.toString(),
                      style: AppTypography.titleMedium.copyWith(
                        color: _getRankingColor(rank),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nickname,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '활동 ${entry.activities}개',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Points
          Text(
            '${entry.points}P',
            style: AppTypography.titleLarge.copyWith(
              color: _getRankingColor(rank),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * (rank - 1)))
        .fadeIn()
        .slideY(begin: 0.1);
  }

  Color _getRankingColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textSecondary;
    }
  }
}