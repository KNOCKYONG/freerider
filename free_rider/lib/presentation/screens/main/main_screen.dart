import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../home/home_screen.dart';
import '../activity/activity_screen.dart';
import '../mission/mission_screen.dart';
import '../card/card_screen.dart';
import '../profile/profile_screen.dart';

final currentIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);
    
    final List<Widget> pages = [
      const HomeScreen(),
      const ActivityScreen(),
      const MissionScreen(),
      const CardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: AppSpacing.bottomNavHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  ref,
                  index: 0,
                  icon: Icons.home_rounded,
                  label: '홈',
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  ref,
                  index: 1,
                  icon: Icons.directions_walk_rounded,
                  label: '활동',
                  isSelected: currentIndex == 1,
                ),
                _buildNavItem(
                  ref,
                  index: 2,
                  icon: Icons.flag_rounded,
                  label: '미션',
                  isSelected: currentIndex == 2,
                ),
                _buildNavItem(
                  ref,
                  index: 3,
                  icon: Icons.credit_card_rounded,
                  label: '카드',
                  isSelected: currentIndex == 3,
                ),
                _buildNavItem(
                  ref,
                  index: 4,
                  icon: Icons.person_rounded,
                  label: '프로필',
                  isSelected: currentIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    WidgetRef ref, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(currentIndexProvider.notifier).state = index,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected 
                  ? AppColors.primaryGreen 
                  : AppColors.gray400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected 
                    ? AppColors.primaryGreen 
                    : AppColors.gray400,
                fontWeight: isSelected 
                    ? FontWeight.w600 
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}