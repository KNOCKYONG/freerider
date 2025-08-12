import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/commerce/delivery_cashback_service.dart';
import '../../../data/providers/points_provider.dart';

class DeliveryCashbackScreen extends ConsumerStatefulWidget {
  const DeliveryCashbackScreen({super.key});

  @override
  ConsumerState<DeliveryCashbackScreen> createState() => _DeliveryCashbackScreenState();
}

class _DeliveryCashbackScreenState extends ConsumerState<DeliveryCashbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeliveryCashbackService _cashbackService = DeliveryCashbackService();
  
  List<PartnerRestaurant> _restaurants = [];
  List<DeliveryCashbackRecord> _history = [];
  List<CashbackCampaign> _campaigns = [];
  DeliveryCashbackStats? _stats;
  bool _isLoading = true;
  
  // 필터
  String? _selectedPartnerId;
  String? _selectedCategory;

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
    await _cashbackService.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final restaurants = _cashbackService.getPartnerRestaurants();
      final history = _cashbackService.getCashbackHistory('user_001');
      final campaigns = _cashbackService.getActiveCampaigns();
      final stats = _cashbackService.getUserStats('user_001');
      
      setState(() {
        _restaurants = restaurants;
        _history = history;
        _campaigns = campaigns;
        _stats = stats;
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
        title: const Text('배달 캐시백'),
        backgroundColor: AppColors.backgroundPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: '제휴매장'),
            Tab(text: '캠페인'),
            Tab(text: '내역'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRestaurantsTab(),
          _buildCampaignsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // 필터링
    var filtered = _restaurants;
    if (_selectedPartnerId != null) {
      filtered = filtered
          .where((r) => r.partnerIds.contains(_selectedPartnerId))
          .toList();
    }
    if (_selectedCategory != null) {
      filtered = filtered
          .where((r) => r.category == _selectedCategory)
          .toList();
    }
    
    return Column(
      children: [
        // 통계 카드
        if (_stats != null) _buildStatsCard(),
        
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
                _buildFilterChip('전체', null, isPartner: true),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('배민', 'baemin', isPartner: true),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('쿠팡이츠', 'coupangeats', isPartner: true),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('요기요', 'yogiyo', isPartner: true),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.border,
                ),
                const SizedBox(width: AppSpacing.md),
                _buildFilterChip('치킨', '치킨', isPartner: false),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('버거', '버거', isPartner: false),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('카페', '카페', isPartner: false),
              ],
            ),
          ),
        ),
        
        // 매장 목록
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.screenPaddingHorizontal,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildRestaurantCard(filtered[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignsTab() {
    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_rounded,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '진행 중인 캠페인이 없습니다',
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
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        return _buildCampaignCard(_campaigns[index]);
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '캐시백 내역이 없습니다',
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
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(_history[index]);
      },
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.rewardOrange,
            AppColors.rewardOrange.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppSpacing.shadowMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '총 주문',
            '${_stats!.totalOrders}건',
            Icons.receipt_long_rounded,
          ),
          _buildStatItem(
            '총 캐시백',
            '${_stats!.totalEarned}P',
            Icons.savings_rounded,
          ),
          _buildStatItem(
            '평균',
            '${_stats!.averageCashback}P',
            Icons.trending_up_rounded,
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

  Widget _buildRestaurantCard(PartnerRestaurant restaurant) {
    // 최대 캐시백 계산
    int maxCashback = 0;
    String bestPartner = '';
    
    for (final partnerId in restaurant.partnerIds) {
      final cashback = _cashbackService.calculateExpectedCashback(
        partnerId: partnerId,
        restaurantId: restaurant.id,
        orderAmount: 20000, // 기준 금액
      );
      if (cashback > maxCashback) {
        maxCashback = cashback;
        bestPartner = partnerId;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showRestaurantDetail(restaurant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 카테고리 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  _getCategoryIcon(restaurant.category),
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${restaurant.averageDeliveryTime}분',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '최소 ${restaurant.minimumOrder}원',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // 제휴 앱 아이콘
                    Row(
                      children: restaurant.partnerIds.map((id) {
                        return Container(
                          margin: const EdgeInsets.only(right: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPartnerColor(id).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            _getPartnerShortName(id),
                            style: AppTypography.labelSmall.copyWith(
                              color: _getPartnerColor(id),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // 캐시백
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '최대',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(maxCashback * 100 / 20000).toStringAsFixed(0)}%',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.rewardOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '캐시백',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildCampaignCard(CashbackCampaign campaign) {
    final remaining = campaign.endDate.difference(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.rewardOrange.withOpacity(0.1),
            AppColors.rewardOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.rewardOrange.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.rewardOrange,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      campaign.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rewardOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'D-${remaining.inDays}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.rewardOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildCampaignBenefit(campaign),
            if (campaign.partnerId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.store_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    DeliveryCashbackService.partners[campaign.partnerId]!.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildCampaignBenefit(CashbackCampaign campaign) {
    switch (campaign.type) {
      case CampaignType.percentage:
        return Text(
          '추가 ${(campaign.bonusRate * 100).toStringAsFixed(0)}% 캐시백',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.rewardOrange,
            fontWeight: FontWeight.w600,
          ),
        );
      case CampaignType.fixed:
        return Text(
          '${campaign.fixedBonus}P 보너스',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.rewardOrange,
            fontWeight: FontWeight.w600,
          ),
        );
      case CampaignType.firstOrder:
        return Text(
          '첫 주문 ${campaign.fixedBonus}P 보너스',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.rewardOrange,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }

  Widget _buildHistoryCard(DeliveryCashbackRecord record) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (record.status) {
      case CashbackStatus.completed:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = '적립완료';
        break;
      case CashbackStatus.pending:
      case CashbackStatus.confirmed:
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
        statusText = '대기중';
        break;
      case CashbackStatus.failed:
      case CashbackStatus.cancelled:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusText = '취소';
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              Expanded(
                child: Text(
                  record.restaurantName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    statusText,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '주문금액: ${record.orderAmount.toStringAsFixed(0)}원',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '+${record.cashbackAmount}P',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (record.campaignBonus > 0) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '캠페인 보너스 +${record.campaignBonus}P 포함',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.rewardOrange,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _formatDate(record.createdAt),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, {required bool isPartner}) {
    final isSelected = isPartner
        ? _selectedPartnerId == value
        : _selectedCategory == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (isPartner) {
            _selectedPartnerId = selected ? value : null;
          } else {
            _selectedCategory = selected ? value : null;
          }
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

  void _showRestaurantDetail(PartnerRestaurant restaurant) {
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
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => _buildRestaurantDetailSheet(
          restaurant,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildRestaurantDetailSheet(
    PartnerRestaurant restaurant,
    ScrollController scrollController,
  ) {
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
                Text(
                  restaurant.name,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      restaurant.category,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '${restaurant.averageDeliveryTime}분',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 캐시백 정보
                Text(
                  '캐시백 정보',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                ...restaurant.partnerIds.map((partnerId) {
                  final partner = DeliveryCashbackService.partners[partnerId]!;
                  final cashback = _cashbackService.calculateExpectedCashback(
                    partnerId: partnerId,
                    restaurantId: restaurant.id,
                    orderAmount: 20000,
                  );
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _getPartnerColor(partnerId).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                              child: Text(
                                partner.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: _getPartnerColor(partnerId),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(partner.cashbackRate * 100).toStringAsFixed(0)}%',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '최대 ${partner.maxCashback}P',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 주문하기 버튼들
                Text(
                  '주문하기',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                ...restaurant.partnerIds.map((partnerId) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ElevatedButton(
                      onPressed: () => _startOrder(restaurant, partnerId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getPartnerColor(partnerId),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delivery_dining_rounded, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${DeliveryCashbackService.partners[partnerId]!.name}로 주문',
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startOrder(PartnerRestaurant restaurant, String partnerId) async {
    Navigator.pop(context);
    
    // 예상 주문 금액 (실제로는 사용자 입력)
    const orderAmount = 20000.0;
    
    // 주문 추적 시작
    final result = await _cashbackService.startOrderTracking(
      userId: 'user_001',
      partnerId: partnerId,
      restaurantId: restaurant.id,
      orderAmount: orderAmount,
    );
    
    if (result.success) {
      // 딥링크 실행
      try {
        final uri = Uri.parse(result.deepLink!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Failed to launch: $e');
      }
      
      // 안내 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예상 캐시백: ${result.estimatedCashback}P'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? '주문 추적 시작 실패'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '치킨':
        return Icons.egg_rounded;
      case '버거':
        return Icons.lunch_dining_rounded;
      case '카페':
        return Icons.coffee_rounded;
      case '피자':
        return Icons.local_pizza_rounded;
      case '한식':
        return Icons.rice_bowl_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _getPartnerColor(String partnerId) {
    switch (partnerId) {
      case 'baemin':
        return const Color(0xFF2AC1BC);
      case 'coupangeats':
        return const Color(0xFF1E90FF);
      case 'yogiyo':
        return const Color(0xFFFB3B5A);
      default:
        return AppColors.primaryGreen;
    }
  }

  String _getPartnerShortName(String partnerId) {
    switch (partnerId) {
      case 'baemin':
        return '배민';
      case 'coupangeats':
        return '쿠이';
      case 'yogiyo':
        return '요기';
      default:
        return partnerId;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}