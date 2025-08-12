import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/ads/offerwall_service.dart';
import '../../../data/providers/points_provider.dart';

class OfferwallScreen extends ConsumerStatefulWidget {
  const OfferwallScreen({super.key});

  @override
  ConsumerState<OfferwallScreen> createState() => _OfferwallScreenState();
}

class _OfferwallScreenState extends ConsumerState<OfferwallScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OfferwallService _offerwallService = OfferwallService();
  
  List<OfferwallOffer> _availableOffers = [];
  List<PendingReward> _pendingRewards = [];
  OfferStatistics? _statistics;
  bool _isLoading = true;
  
  // 필터
  OfferType? _selectedType;
  String _sortBy = 'points'; // points, time, difficulty

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
    await _offerwallService.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final offers = await _offerwallService.getAvailableOffers('user_001');
      final pending = _offerwallService.getPendingRewards('user_001');
      final stats = _offerwallService.getStatistics('user_001');
      
      setState(() {
        _availableOffers = offers;
        _pendingRewards = pending;
        _statistics = stats;
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
        title: const Text('오퍼월'),
        backgroundColor: AppColors.backgroundPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: '추천'),
            Tab(text: '전체'),
            Tab(text: '대기중'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecommendedTab(),
          _buildAllOffersTab(),
          _buildPendingTab(),
        ],
      ),
    );
  }

  Widget _buildRecommendedTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final highValueOffers = _availableOffers
        .where((o) => o.isHighValue || o.points >= 1000)
        .take(5)
        .toList();
    
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // 통계 카드
          if (_statistics != null) _buildStatsCard(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 고수익 오퍼
          Text(
            '🔥 고수익 미션',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ...highValueOffers.map((offer) => _buildOfferCard(offer, featured: true)),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 쉬운 미션
          Text(
            '⚡ 빠른 미션',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ..._availableOffers
              .where((o) => o.type == OfferType.survey || o.type == OfferType.video)
              .take(3)
              .map((offer) => _buildOfferCard(offer)),
          
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildAllOffersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // 필터링
    var filtered = _availableOffers;
    if (_selectedType != null) {
      filtered = filtered.where((o) => o.type == _selectedType).toList();
    }
    
    // 정렬
    switch (_sortBy) {
      case 'points':
        filtered.sort((a, b) => b.points.compareTo(a.points));
        break;
      case 'time':
        filtered.sort((a, b) => a.estimatedTimePerItem.compareTo(b.estimatedTimePerItem));
        break;
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
          child: Row(
            children: [
              // 타입 필터
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('전체', null),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('앱설치', OfferType.appInstall),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('가입', OfferType.signup),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('설문', OfferType.survey),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('게임', OfferType.gameLevel),
                    ],
                  ),
                ),
              ),
              
              // 정렬
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded),
                onSelected: (value) {
                  setState(() => _sortBy = value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'points',
                    child: Text('포인트 높은순'),
                  ),
                  const PopupMenuItem(
                    value: 'time',
                    child: Text('시간 짧은순'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 오퍼 목록
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.screenPaddingHorizontal,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(filtered[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '대기 중인 보상이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: AppSpacing.screenPaddingHorizontal,
      itemCount: _pendingRewards.length,
      itemBuilder: (context, index) {
        return _buildPendingCard(_pendingRewards[index]);
      },
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '완료',
                '${_statistics!.completedCount}개',
                Icons.check_circle_rounded,
              ),
              _buildStatItem(
                '획득',
                '${_statistics!.totalEarnedPoints}P',
                Icons.stars_rounded,
              ),
              _buildStatItem(
                '대기',
                '${_statistics!.pendingPoints}P',
                Icons.schedule_rounded,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 24,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(OfferwallOffer offer, {bool featured = false}) {
    final typeInfo = _getOfferTypeInfo(offer.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: featured ? AppColors.primaryGreen : AppColors.border,
          width: featured ? 2 : 1,
        ),
        boxShadow: featured ? AppSpacing.shadowMd : null,
      ),
      child: InkWell(
        onTap: () => _showOfferDetail(offer),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: typeInfo.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.color,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (featured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rewardOrange,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                            ),
                            child: Text(
                              'HOT',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (featured) const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            offer.title,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      offer.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '약 ${offer.estimatedTimePerItem}초',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            typeInfo.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
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
                    '${offer.points}',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'P',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: featured ? 0 : 100));
  }

  Widget _buildPendingCard(PendingReward reward) {
    final remaining = reward.expiresAt.difference(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '처리 대기중',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${reward.points}P',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '오퍼 ID: ${reward.offerId}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '만료까지 ${remaining.inDays}일 ${remaining.inHours % 24}시간',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, OfferType? type) {
    final isSelected = _selectedType == type;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
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

  void _showOfferDetail(OfferwallOffer offer) {
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
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _buildOfferDetailSheet(
          offer,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildOfferDetailSheet(
    OfferwallOffer offer,
    ScrollController scrollController,
  ) {
    final typeInfo = _getOfferTypeInfo(offer.type);
    
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
                        color: typeInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        typeInfo.icon,
                        color: typeInfo.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                ),
                                child: Text(
                                  typeInfo.label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '약 ${offer.estimatedTimePerItem}초',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 포인트
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${offer.points} 포인트',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 설명
                Text(
                  '미션 설명',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  offer.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 요구사항
                Text(
                  '완료 조건',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...offer.requirements.map((req) => Padding(
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
                          req,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 주의사항
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '주의사항',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '• 반드시 새로 설치/가입해야 합니다\n'
                              '• 조건 완료 후 최대 7일 내 포인트 지급\n'
                              '• 부정 이용 시 포인트 회수 및 이용 제한',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
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
            onPressed: () => _startOffer(offer),
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
                const Icon(Icons.rocket_launch_rounded, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '미션 시작하기',
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

  Future<void> _startOffer(OfferwallOffer offer) async {
    Navigator.pop(context);
    
    // 오퍼 시작 추적
    await _offerwallService.startOffer('user_001', offer.id);
    
    // 딥링크 실행
    try {
      final uri = Uri.parse(offer.deepLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 웹 브라우저로 열기
        await launchUrl(
          Uri.parse(offer.deepLink),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('앱을 열 수 없습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    
    // 데이터 새로고침
    await _loadData();
  }

  _OfferTypeInfo _getOfferTypeInfo(OfferType type) {
    switch (type) {
      case OfferType.appInstall:
        return _OfferTypeInfo(
          label: '앱설치',
          icon: Icons.download_rounded,
          color: AppColors.subwayBlue,
        );
      case OfferType.signup:
        return _OfferTypeInfo(
          label: '회원가입',
          icon: Icons.person_add_rounded,
          color: AppColors.primaryGreen,
        );
      case OfferType.purchase:
        return _OfferTypeInfo(
          label: '구매',
          icon: Icons.shopping_cart_rounded,
          color: AppColors.rewardOrange,
        );
      case OfferType.gameLevel:
        return _OfferTypeInfo(
          label: '게임',
          icon: Icons.sports_esports_rounded,
          color: AppColors.cognitiveColor,
        );
      case OfferType.survey:
        return _OfferTypeInfo(
          label: '설문',
          icon: Icons.quiz_rounded,
          color: AppColors.visualColor,
        );
      case OfferType.creditCard:
        return _OfferTypeInfo(
          label: '카드발급',
          icon: Icons.credit_card_rounded,
          color: AppColors.error,
        );
      case OfferType.subscription:
        return _OfferTypeInfo(
          label: '구독',
          icon: Icons.subscriptions_rounded,
          color: AppColors.warning,
        );
      case OfferType.video:
        return _OfferTypeInfo(
          label: '동영상',
          icon: Icons.play_circle_rounded,
          color: AppColors.movementColor,
        );
      case OfferType.social:
        return _OfferTypeInfo(
          label: 'SNS',
          icon: Icons.share_rounded,
          color: AppColors.voiceColor,
        );
    }
  }
}

class _OfferTypeInfo {
  final String label;
  final IconData icon;
  final Color color;

  _OfferTypeInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}