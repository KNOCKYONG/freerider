import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/commerce/affiliate_service.dart';
import '../../widgets/common/primary_button.dart';

/// 제휴 쇼핑몰 화면
/// 구매 시 캐시백 포인트 제공
class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AffiliateService _affiliateService = AffiliateService();
  
  String _selectedCategory = '전체';
  String _sortBy = 'popular'; // popular, cashback, price_low, price_high
  List<Product> _products = [];
  bool _isLoading = true;

  final List<String> _categories = [
    '전체',
    '패션',
    '뷰티',
    '식품',
    '가전',
    '생활',
    '디지털',
    '스포츠',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await _affiliateService.getProducts(
        category: _selectedCategory,
        sortBy: _sortBy,
      );
      
      setState(() {
        _products = products;
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
        title: const Text('포인트 쇼핑'),
        backgroundColor: AppColors.backgroundPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: '인기상품'),
            Tab(text: '타임딜'),
            Tab(text: '베스트 캐시백'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList(),
          _buildTimeDealList(),
          _buildBestCashbackList(),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.primaryGreen,
      child: CustomScrollView(
        slivers: [
          // 카테고리 필터
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          
          // 정렬 옵션
          SliverToBoxAdapter(
            child: _buildSortOptions(),
          ),
          
          // 캐시백 안내 배너
          SliverToBoxAdapter(
            child: _buildCashbackBanner(),
          ),
          
          // 상품 그리드
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverPadding(
                  padding: AppSpacing.screenPaddingHorizontal,
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductCard(_products[index]),
                      childCount: _products.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTimeDealList() {
    final timeDealProducts = _getTimeDealProducts();
    
    return ListView.builder(
      padding: AppSpacing.screenPaddingHorizontal,
      itemCount: timeDealProducts.length,
      itemBuilder: (context, index) {
        return _buildTimeDealCard(timeDealProducts[index]);
      },
    );
  }

  Widget _buildBestCashbackList() {
    final bestCashbackProducts = _getBestCashbackProducts();
    
    return ListView.builder(
      padding: AppSpacing.screenPaddingHorizontal,
      itemCount: bestCashbackProducts.length,
      itemBuilder: (context, index) {
        return _buildCashbackCard(bestCashbackProducts[index]);
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPaddingHorizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
                _loadProducts();
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primaryGreen.withOpacity(0.2),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primaryGreen : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: AppSpacing.screenPaddingHorizontal,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_products.length}개 상품',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox(),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
            items: const [
              DropdownMenuItem(value: 'popular', child: Text('인기순')),
              DropdownMenuItem(value: 'cashback', child: Text('캐시백 높은순')),
              DropdownMenuItem(value: 'price_low', child: Text('가격 낮은순')),
              DropdownMenuItem(value: 'price_high', child: Text('가격 높은순')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
                _loadProducts();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCashbackBanner() {
    return Container(
      margin: AppSpacing.screenPaddingHorizontal,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.1),
            AppColors.rewardOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '구매하고 포인트 받자!',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '최대 10% 캐시백 포인트 적립',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      onTap: () => _openProductDetail(product),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMd),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.gray100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.gray100,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 캐시백 뱃지
                if (product.cashbackRate > 0)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rewardOrange,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        '${product.cashbackRate}%',
                        style: AppTypography.labelXSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // 상품 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 브랜드
                    Text(
                      product.brand,
                      style: AppTypography.labelXSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // 상품명
                    Text(
                      product.name,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // 가격
                    Row(
                      children: [
                        if (product.originalPrice != product.price) ...[
                          Text(
                            '${product.originalPrice.toStringAsFixed(0)}원',
                            style: AppTypography.labelXSmall.copyWith(
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        Text(
                          '${product.price.toStringAsFixed(0)}원',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xxs),
                    
                    // 캐시백 포인트
                    if (product.cashbackPoints > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text(
                          '+${product.cashbackPoints}P',
                          style: AppTypography.labelXSmall.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50));
  }

  Widget _buildTimeDealCard(Product product) {
    final remainingTime = product.dealEndTime!.difference(DateTime.now());
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes % 60;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _openProductDetail(product),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.gray100,
                  ),
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타이머
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      child: Text(
                        '⏰ ${hours}시간 ${minutes}분 남음',
                        style: AppTypography.labelXSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: AppSpacing.xxs),
                    
                    // 가격
                    Row(
                      children: [
                        Text(
                          '${product.originalPrice.toStringAsFixed(0)}원',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${product.price.toStringAsFixed(0)}원',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xxs),
                    
                    // 할인율 & 캐시백
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            '${product.discountRate}% OFF',
                            style: AppTypography.labelXSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '+${product.cashbackPoints}P',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashbackCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _openProductDetail(product),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.gray100,
                  ),
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.savings_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                '최대 ${product.cashbackRate}%',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    Text(
                      product.brand,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xxs),
                    
                    Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)}원',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                            '+${product.cashbackPoints}P 적립',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProductDetail(Product product) {
    // 상품 상세 페이지로 이동
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
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ProductDetailSheet(
          product: product,
          scrollController: scrollController,
        ),
      ),
    );
  }

  List<Product> _getTimeDealProducts() {
    // Mock 타임딜 상품
    return List.generate(5, (index) => Product(
      id: 'deal_$index',
      name: '타임딜 상품 ${index + 1}',
      brand: '브랜드 ${index + 1}',
      price: (index + 1) * 10000,
      originalPrice: (index + 1) * 15000,
      imageUrl: 'https://via.placeholder.com/300',
      cashbackRate: 5.0 + index,
      cashbackPoints: ((index + 1) * 10000 * (5.0 + index) / 100).toInt(),
      discountRate: 30 + index * 5,
      dealEndTime: DateTime.now().add(Duration(hours: index + 1)),
      affiliate: 'coupang',
    ));
  }

  List<Product> _getBestCashbackProducts() {
    // Mock 베스트 캐시백 상품
    return List.generate(10, (index) => Product(
      id: 'cashback_$index',
      name: '베스트 캐시백 상품 ${index + 1}',
      brand: '프리미엄 브랜드 ${index + 1}',
      price: (index + 1) * 20000,
      originalPrice: (index + 1) * 20000,
      imageUrl: 'https://via.placeholder.com/300',
      cashbackRate: 10.0 - index * 0.5,
      cashbackPoints: ((index + 1) * 20000 * (10.0 - index * 0.5) / 100).toInt(),
      affiliate: index % 2 == 0 ? 'coupang' : '11st',
    ));
  }
}

/// 상품 상세 시트
class ProductDetailSheet extends StatelessWidget {
  final Product product;
  final ScrollController scrollController;
  
  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 핸들바
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.gray300,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: AppSpacing.screenPaddingHorizontal,
            children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 상품 정보
              Text(
                product.brand,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xs),
              
              Text(
                product.name,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // 가격 정보
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (product.originalPrice != product.price) ...[
                    Text(
                      '${product.originalPrice.toStringAsFixed(0)}원',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textTertiary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    '${product.price.toStringAsFixed(0)}원',
                    style: AppTypography.displaySmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 캐시백 정보
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '구매 시 캐시백',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${product.cashbackPoints}P (${product.cashbackRate}%)',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // 구매 버튼
              PrimaryButton(
                text: '구매하고 ${product.cashbackPoints}P 받기',
                onPressed: () {
                  // 제휴 링크로 이동
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.affiliate} 쇼핑몰로 이동합니다'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

/// 상품 모델
class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final double cashbackRate;
  final int cashbackPoints;
  final int? discountRate;
  final DateTime? dealEndTime;
  final String affiliate; // coupang, 11st, gmarket, etc.

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.cashbackRate,
    required this.cashbackPoints,
    this.discountRate,
    this.dealEndTime,
    required this.affiliate,
  });
}