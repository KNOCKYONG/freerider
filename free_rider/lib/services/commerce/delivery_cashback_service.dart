import 'dart:async';
import 'package:flutter/foundation.dart';

/// 배달앱 캐시백 서비스
/// 배달 주문 시 포인트 적립
class DeliveryCashbackService {
  static final DeliveryCashbackService _instance = DeliveryCashbackService._internal();
  factory DeliveryCashbackService() => _instance;
  DeliveryCashbackService._internal();

  // 제휴 배달앱
  static const Map<String, DeliveryPartner> partners = {
    'baemin': DeliveryPartner(
      id: 'baemin',
      name: '배달의민족',
      cashbackRate: 0.05, // 5% 캐시백
      maxCashback: 2000,   // 최대 2000P
      minOrder: 10000,     // 최소 주문 10,000원
      apiEndpoint: 'https://api.baemin.com/affiliate',
    ),
    'coupangeats': DeliveryPartner(
      id: 'coupangeats',
      name: '쿠팡이츠',
      cashbackRate: 0.07, // 7% 캐시백
      maxCashback: 3000,   // 최대 3000P
      minOrder: 8000,      // 최소 주문 8,000원
      apiEndpoint: 'https://api.coupangeats.com/affiliate',
    ),
    'yogiyo': DeliveryPartner(
      id: 'yogiyo',
      name: '요기요',
      cashbackRate: 0.04, // 4% 캐시백
      maxCashback: 1500,   // 최대 1500P
      minOrder: 12000,     // 최소 주문 12,000원
      apiEndpoint: 'https://api.yogiyo.co.kr/affiliate',
    ),
  };

  // 캐시백 기록
  final List<DeliveryCashbackRecord> _cashbackHistory = [];
  
  // 사용자별 일일/월간 한도
  final Map<String, UserCashbackLimit> _userLimits = {};
  
  // 제휴점 데이터
  final List<PartnerRestaurant> _partnerRestaurants = [];
  
  // 활성 캠페인
  final List<CashbackCampaign> _activeCampaigns = [];

  /// 서비스 초기화
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _loadPartnerRestaurants();
    _loadActiveCampaigns();
    debugPrint('Delivery cashback service initialized');
  }

  /// 주문 추적 시작
  Future<DeliveryTrackingResult> startOrderTracking({
    required String userId,
    required String partnerId,
    required String restaurantId,
    required double orderAmount,
  }) async {
    try {
      // 유효성 검증
      final validation = _validateOrder(userId, partnerId, orderAmount);
      if (!validation.isValid) {
        return DeliveryTrackingResult(
          success: false,
          error: validation.message,
        );
      }
      
      final partner = partners[partnerId]!;
      
      // 캐시백 계산
      var cashbackAmount = (orderAmount * partner.cashbackRate).toInt();
      
      // 캠페인 보너스 적용
      final campaignBonus = _calculateCampaignBonus(
        partnerId,
        restaurantId,
        orderAmount,
      );
      cashbackAmount += campaignBonus;
      
      // 최대 한도 적용
      cashbackAmount = cashbackAmount.clamp(0, partner.maxCashback);
      
      // 추적 ID 생성
      final trackingId = 'DT_${DateTime.now().millisecondsSinceEpoch}';
      
      // 딥링크 생성
      final deepLink = _generateDeepLink(
        partner,
        restaurantId,
        trackingId,
        userId,
      );
      
      // 추적 기록 저장
      final record = DeliveryCashbackRecord(
        id: trackingId,
        userId: userId,
        partnerId: partnerId,
        restaurantId: restaurantId,
        restaurantName: _getRestaurantName(restaurantId),
        orderAmount: orderAmount,
        cashbackAmount: cashbackAmount,
        campaignBonus: campaignBonus,
        status: CashbackStatus.pending,
        createdAt: DateTime.now(),
      );
      
      _cashbackHistory.add(record);
      
      return DeliveryTrackingResult(
        success: true,
        trackingId: trackingId,
        deepLink: deepLink,
        estimatedCashback: cashbackAmount,
      );
    } catch (e) {
      return DeliveryTrackingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 주문 완료 확인
  Future<CashbackConfirmResult> confirmOrder({
    required String trackingId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      // 추적 기록 찾기
      final record = _cashbackHistory.firstWhere(
        (r) => r.id == trackingId,
      );
      
      // 주문 데이터 검증
      if (!_verifyOrderData(orderData)) {
        record.status = CashbackStatus.failed;
        return CashbackConfirmResult(
          success: false,
          error: 'Invalid order data',
        );
      }
      
      // 실제 주문 금액 확인
      final actualAmount = orderData['amount'] as double;
      if ((actualAmount - record.orderAmount).abs() > 100) {
        // 금액 차이가 100원 이상이면 재계산
        final partner = partners[record.partnerId]!;
        record.cashbackAmount = (actualAmount * partner.cashbackRate).toInt();
        record.orderAmount = actualAmount;
      }
      
      // 상태 업데이트
      record.status = CashbackStatus.confirmed;
      record.confirmedAt = DateTime.now();
      record.orderId = orderData['orderId'] as String;
      
      // 일일/월간 한도 업데이트
      _updateUserLimits(record.userId, record.cashbackAmount);
      
      // 30분 후 자동 적립 (실제로는 배달 완료 확인 후)
      Timer(const Duration(minutes: 30), () {
        if (record.status == CashbackStatus.confirmed) {
          record.status = CashbackStatus.completed;
          record.completedAt = DateTime.now();
        }
      });
      
      return CashbackConfirmResult(
        success: true,
        cashbackAmount: record.cashbackAmount,
        expectedCompletionTime: DateTime.now().add(const Duration(minutes: 30)),
      );
    } catch (e) {
      return CashbackConfirmResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 캐시백 내역 조회
  List<DeliveryCashbackRecord> getCashbackHistory(String userId) {
    return _cashbackHistory
        .where((record) => record.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 제휴 레스토랑 조회
  List<PartnerRestaurant> getPartnerRestaurants({
    String? partnerId,
    String? category,
    double? userLat,
    double? userLng,
    double radiusKm = 3.0,
  }) {
    var restaurants = _partnerRestaurants;
    
    // 배달앱 필터
    if (partnerId != null) {
      restaurants = restaurants
          .where((r) => r.partnerIds.contains(partnerId))
          .toList();
    }
    
    // 카테고리 필터
    if (category != null) {
      restaurants = restaurants
          .where((r) => r.category == category)
          .toList();
    }
    
    // 거리 필터
    if (userLat != null && userLng != null) {
      restaurants = restaurants.where((r) {
        final distance = _calculateDistance(
          userLat,
          userLng,
          r.latitude,
          r.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    }
    
    // 캐시백률 높은 순으로 정렬
    restaurants.sort((a, b) {
      final aRate = _getEffectiveCashbackRate(a.id);
      final bRate = _getEffectiveCashbackRate(b.id);
      return bRate.compareTo(aRate);
    });
    
    return restaurants;
  }

  /// 활성 캠페인 조회
  List<CashbackCampaign> getActiveCampaigns() {
    final now = DateTime.now();
    return _activeCampaigns
        .where((campaign) =>
            campaign.isActive &&
            now.isAfter(campaign.startDate) &&
            now.isBefore(campaign.endDate))
        .toList();
  }

  /// 예상 캐시백 계산
  int calculateExpectedCashback({
    required String partnerId,
    required String restaurantId,
    required double orderAmount,
  }) {
    final partner = partners[partnerId];
    if (partner == null || orderAmount < partner.minOrder) {
      return 0;
    }
    
    var cashback = (orderAmount * partner.cashbackRate).toInt();
    
    // 캠페인 보너스
    cashback += _calculateCampaignBonus(partnerId, restaurantId, orderAmount);
    
    // 최대 한도
    return cashback.clamp(0, partner.maxCashback);
  }

  /// 사용자 캐시백 통계
  DeliveryCashbackStats getUserStats(String userId) {
    final userRecords = _cashbackHistory
        .where((r) => r.userId == userId)
        .toList();
    
    final completedRecords = userRecords
        .where((r) => r.status == CashbackStatus.completed)
        .toList();
    
    final totalEarned = completedRecords.fold<int>(
      0,
      (sum, record) => sum + record.cashbackAmount,
    );
    
    final pendingAmount = userRecords
        .where((r) => r.status == CashbackStatus.pending ||
                     r.status == CashbackStatus.confirmed)
        .fold<int>(0, (sum, record) => sum + record.cashbackAmount);
    
    // 이번 달 통계
    final now = DateTime.now();
    final monthlyRecords = completedRecords
        .where((r) => r.completedAt != null &&
                     r.completedAt!.year == now.year &&
                     r.completedAt!.month == now.month)
        .toList();
    
    final monthlyEarned = monthlyRecords.fold<int>(
      0,
      (sum, record) => sum + record.cashbackAmount,
    );
    
    return DeliveryCashbackStats(
      totalOrders: completedRecords.length,
      totalEarned: totalEarned,
      pendingAmount: pendingAmount,
      monthlyOrders: monthlyRecords.length,
      monthlyEarned: monthlyEarned,
      averageCashback: completedRecords.isEmpty
          ? 0
          : (totalEarned / completedRecords.length).round(),
    );
  }

  // Private methods

  OrderValidation _validateOrder(
    String userId,
    String partnerId,
    double orderAmount,
  ) {
    final partner = partners[partnerId];
    if (partner == null) {
      return OrderValidation(
        isValid: false,
        message: '제휴하지 않은 배달앱입니다',
      );
    }
    
    if (orderAmount < partner.minOrder) {
      return OrderValidation(
        isValid: false,
        message: '최소 주문금액 ${partner.minOrder}원 이상부터 캐시백 가능합니다',
      );
    }
    
    // 일일 한도 체크
    final userLimit = _userLimits[userId];
    if (userLimit != null && userLimit.dailyAmount >= 10000) {
      return OrderValidation(
        isValid: false,
        message: '일일 캐시백 한도(10,000P)를 초과했습니다',
      );
    }
    
    return OrderValidation(isValid: true);
  }

  bool _verifyOrderData(Map<String, dynamic> data) {
    return data.containsKey('orderId') &&
           data.containsKey('amount') &&
           data.containsKey('timestamp');
  }

  String _generateDeepLink(
    DeliveryPartner partner,
    String restaurantId,
    String trackingId,
    String userId,
  ) {
    // 실제로는 각 배달앱의 딥링크 스펙에 맞게 생성
    switch (partner.id) {
      case 'baemin':
        return 'baemin://restaurant/$restaurantId?tracking=$trackingId&uid=$userId';
      case 'coupangeats':
        return 'coupangeats://store/$restaurantId?tid=$trackingId&user=$userId';
      case 'yogiyo':
        return 'yogiyo://restaurant?id=$restaurantId&tracking=$trackingId';
      default:
        return '';
    }
  }

  int _calculateCampaignBonus(
    String partnerId,
    String restaurantId,
    double orderAmount,
  ) {
    var bonus = 0;
    
    for (final campaign in _activeCampaigns) {
      if (campaign.isActive &&
          (campaign.partnerId == null || campaign.partnerId == partnerId) &&
          (campaign.restaurantIds.isEmpty || 
           campaign.restaurantIds.contains(restaurantId))) {
        
        switch (campaign.type) {
          case CampaignType.percentage:
            bonus += (orderAmount * campaign.bonusRate).toInt();
            break;
          case CampaignType.fixed:
            bonus += campaign.fixedBonus;
            break;
          case CampaignType.firstOrder:
            // 첫 주문 체크 로직
            final hasOrdered = _cashbackHistory.any(
              (r) => r.userId == partnerId && r.restaurantId == restaurantId,
            );
            if (!hasOrdered) {
              bonus += campaign.fixedBonus;
            }
            break;
        }
      }
    }
    
    return bonus;
  }

  double _getEffectiveCashbackRate(String restaurantId) {
    // 기본 캐시백률 + 캠페인 보너스 계산
    var maxRate = 0.0;
    
    for (final partnerId in partners.keys) {
      final baseRate = partners[partnerId]!.cashbackRate;
      final campaignBonus = _calculateCampaignBonus(
        partnerId,
        restaurantId,
        10000, // 기준 금액
      ) / 10000;
      
      maxRate = (baseRate + campaignBonus).clamp(0.0, 1.0);
    }
    
    return maxRate;
  }

  void _updateUserLimits(String userId, int amount) {
    final now = DateTime.now();
    var limit = _userLimits[userId];
    
    if (limit == null) {
      limit = UserCashbackLimit(
        userId: userId,
        dailyAmount: amount,
        monthlyAmount: amount,
        lastUpdated: now,
      );
      _userLimits[userId] = limit;
    } else {
      // 일일 리셋
      if (now.day != limit.lastUpdated.day) {
        limit.dailyAmount = amount;
      } else {
        limit.dailyAmount += amount;
      }
      
      // 월간 리셋
      if (now.month != limit.lastUpdated.month) {
        limit.monthlyAmount = amount;
      } else {
        limit.monthlyAmount += amount;
      }
      
      limit.lastUpdated = now;
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Haversine formula
    const earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(_toRadians(lat1)) * Math.cos(_toRadians(lat2)) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
    
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * Math.pi / 180;

  String _getRestaurantName(String restaurantId) {
    try {
      return _partnerRestaurants
          .firstWhere((r) => r.id == restaurantId)
          .name;
    } catch (_) {
      return '알 수 없는 매장';
    }
  }

  void _loadPartnerRestaurants() {
    _partnerRestaurants.addAll([
      PartnerRestaurant(
        id: 'rest_001',
        name: 'BBQ 치킨 강남점',
        category: '치킨',
        partnerIds: ['baemin', 'coupangeats', 'yogiyo'],
        latitude: 37.4979,
        longitude: 127.0276,
        averageDeliveryTime: 35,
        minimumOrder: 15000,
      ),
      PartnerRestaurant(
        id: 'rest_002',
        name: '맥도날드 역삼점',
        category: '버거',
        partnerIds: ['baemin', 'coupangeats'],
        latitude: 37.5006,
        longitude: 127.0364,
        averageDeliveryTime: 25,
        minimumOrder: 10000,
      ),
      PartnerRestaurant(
        id: 'rest_003',
        name: '스타벅스 선릉점',
        category: '카페',
        partnerIds: ['coupangeats'],
        latitude: 37.5048,
        longitude: 127.0486,
        averageDeliveryTime: 20,
        minimumOrder: 8000,
      ),
    ]);
  }

  void _loadActiveCampaigns() {
    _activeCampaigns.addAll([
      CashbackCampaign(
        id: 'camp_001',
        name: '첫 주문 보너스',
        type: CampaignType.firstOrder,
        fixedBonus: 2000,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 30)),
      ),
      CashbackCampaign(
        id: 'camp_002',
        name: '주말 특별 캐시백',
        type: CampaignType.percentage,
        bonusRate: 0.02, // 추가 2%
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        daysOfWeek: [6, 7], // 토, 일
      ),
    ]);
  }
}

// Models

class DeliveryPartner {
  final String id;
  final String name;
  final double cashbackRate;
  final int maxCashback;
  final int minOrder;
  final String apiEndpoint;

  const DeliveryPartner({
    required this.id,
    required this.name,
    required this.cashbackRate,
    required this.maxCashback,
    required this.minOrder,
    required this.apiEndpoint,
  });
}

class DeliveryCashbackRecord {
  final String id;
  final String userId;
  final String partnerId;
  final String restaurantId;
  final String restaurantName;
  double orderAmount;
  int cashbackAmount;
  final int campaignBonus;
  CashbackStatus status;
  final DateTime createdAt;
  DateTime? confirmedAt;
  DateTime? completedAt;
  String? orderId;

  DeliveryCashbackRecord({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.restaurantId,
    required this.restaurantName,
    required this.orderAmount,
    required this.cashbackAmount,
    required this.campaignBonus,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.orderId,
  });
}

enum CashbackStatus {
  pending,    // 주문 대기
  confirmed,  // 주문 확인
  completed,  // 캐시백 완료
  failed,     // 실패
  cancelled,  // 취소
}

class PartnerRestaurant {
  final String id;
  final String name;
  final String category;
  final List<String> partnerIds;
  final double latitude;
  final double longitude;
  final int averageDeliveryTime;
  final int minimumOrder;

  PartnerRestaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.partnerIds,
    required this.latitude,
    required this.longitude,
    required this.averageDeliveryTime,
    required this.minimumOrder,
  });
}

class CashbackCampaign {
  final String id;
  final String name;
  final CampaignType type;
  final double bonusRate;
  final int fixedBonus;
  final DateTime startDate;
  final DateTime endDate;
  final String? partnerId;
  final List<String> restaurantIds;
  final List<int>? daysOfWeek;
  final bool isActive;

  CashbackCampaign({
    required this.id,
    required this.name,
    required this.type,
    this.bonusRate = 0,
    this.fixedBonus = 0,
    required this.startDate,
    required this.endDate,
    this.partnerId,
    this.restaurantIds = const [],
    this.daysOfWeek,
    this.isActive = true,
  });
}

enum CampaignType {
  percentage,  // 퍼센트 보너스
  fixed,       // 고정 금액
  firstOrder,  // 첫 주문
}

class DeliveryTrackingResult {
  final bool success;
  final String? trackingId;
  final String? deepLink;
  final int? estimatedCashback;
  final String? error;

  DeliveryTrackingResult({
    required this.success,
    this.trackingId,
    this.deepLink,
    this.estimatedCashback,
    this.error,
  });
}

class CashbackConfirmResult {
  final bool success;
  final int? cashbackAmount;
  final DateTime? expectedCompletionTime;
  final String? error;

  CashbackConfirmResult({
    required this.success,
    this.cashbackAmount,
    this.expectedCompletionTime,
    this.error,
  });
}

class DeliveryCashbackStats {
  final int totalOrders;
  final int totalEarned;
  final int pendingAmount;
  final int monthlyOrders;
  final int monthlyEarned;
  final int averageCashback;

  DeliveryCashbackStats({
    required this.totalOrders,
    required this.totalEarned,
    required this.pendingAmount,
    required this.monthlyOrders,
    required this.monthlyEarned,
    required this.averageCashback,
  });
}

class OrderValidation {
  final bool isValid;
  final String? message;

  OrderValidation({
    required this.isValid,
    this.message,
  });
}

class UserCashbackLimit {
  final String userId;
  int dailyAmount;
  int monthlyAmount;
  DateTime lastUpdated;

  UserCashbackLimit({
    required this.userId,
    required this.dailyAmount,
    required this.monthlyAmount,
    required this.lastUpdated,
  });
}

// Math helpers
class Math {
  static double sin(double x) => x;  // Simplified
  static double cos(double x) => x;  // Simplified
  static double sqrt(double x) => x; // Simplified
  static double atan2(double y, double x) => y / x; // Simplified
  static const double pi = 3.14159265359;
}