import 'dart:async';
import 'package:flutter/foundation.dart';

/// 오퍼월 광고 서비스
/// 앱 설치, 회원가입 등 미션 수행 시 높은 포인트 제공
class OfferwallService {
  static final OfferwallService _instance = OfferwallService._internal();
  factory OfferwallService() => _instance;
  OfferwallService._internal();

  // 오퍼월 제공사
  static const Map<String, OfferwallProvider> providers = {
    'adpopcorn': OfferwallProvider(
      name: '애드팝콘',
      apiKey: 'YOUR_ADPOPCORN_KEY',
      baseUrl: 'https://api.adpopcorn.com',
    ),
    'tnkfactory': OfferwallProvider(
      name: 'TNK Factory',
      apiKey: 'YOUR_TNK_KEY',
      baseUrl: 'https://api.tnkfactory.com',
    ),
    'nas': OfferwallProvider(
      name: 'NAS',
      apiKey: 'YOUR_NAS_KEY',
      baseUrl: 'https://api.nasmedia.co.kr',
    ),
  };

  // 활성 오퍼 목록
  final List<OfferwallOffer> _activeOffers = [];
  
  // 완료된 오퍼 기록
  final Map<String, List<String>> _completedOffers = {};
  
  // 대기 중인 보상
  final Map<String, PendingReward> _pendingRewards = {};

  /// 오퍼월 초기화
  Future<void> initialize() async {
    // Mock 초기화 (실제로는 각 SDK 초기화)
    await Future.delayed(const Duration(seconds: 1));
    
    // 샘플 오퍼 로드
    _loadSampleOffers();
    
    debugPrint('Offerwall service initialized');
  }

  /// 사용 가능한 오퍼 목록 가져오기
  Future<List<OfferwallOffer>> getAvailableOffers(String userId) async {
    // 완료하지 않은 오퍼만 필터링
    final completedIds = _completedOffers[userId] ?? [];
    
    return _activeOffers
        .where((offer) => 
            !completedIds.contains(offer.id) &&
            offer.isActive &&
            DateTime.now().isBefore(offer.expiresAt))
        .toList()
      ..sort((a, b) => b.points.compareTo(a.points)); // 포인트 높은 순
  }

  /// 오퍼 시작 (클릭 추적)
  Future<void> startOffer(String userId, String offerId) async {
    final offer = _activeOffers.firstWhere((o) => o.id == offerId);
    
    // 클릭 추적 (실제로는 제공사 API 호출)
    await _trackClick(userId, offer);
    
    // 대기 중인 보상 등록
    _pendingRewards['${userId}_$offerId'] = PendingReward(
      userId: userId,
      offerId: offerId,
      points: offer.points,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    
    debugPrint('Offer started: ${offer.title} for user $userId');
  }

  /// 오퍼 완료 확인 (콜백)
  Future<OfferCompletionResult> checkCompletion(
    String userId,
    String offerId,
    Map<String, dynamic> callbackData,
  ) async {
    try {
      // 서명 검증 (보안)
      if (!_verifyCallback(callbackData)) {
        return OfferCompletionResult(
          success: false,
          error: 'Invalid callback signature',
        );
      }
      
      // 중복 완료 체크
      final completedIds = _completedOffers[userId] ?? [];
      if (completedIds.contains(offerId)) {
        return OfferCompletionResult(
          success: false,
          error: 'Offer already completed',
        );
      }
      
      // 오퍼 찾기
      final offer = _activeOffers.firstWhere((o) => o.id == offerId);
      
      // 완료 처리
      _completedOffers[userId] = [...completedIds, offerId];
      _pendingRewards.remove('${userId}_$offerId');
      
      return OfferCompletionResult(
        success: true,
        points: offer.points,
        offerId: offerId,
      );
    } catch (e) {
      return OfferCompletionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 대기 중인 보상 조회
  List<PendingReward> getPendingRewards(String userId) {
    return _pendingRewards.values
        .where((reward) => reward.userId == userId)
        .toList();
  }

  /// 오퍼 통계
  OfferStatistics getStatistics(String userId) {
    final completed = _completedOffers[userId] ?? [];
    final pending = getPendingRewards(userId);
    
    final totalEarned = completed.fold<int>(0, (sum, offerId) {
      try {
        final offer = _activeOffers.firstWhere((o) => o.id == offerId);
        return sum + offer.points;
      } catch (_) {
        return sum;
      }
    });
    
    final pendingPoints = pending.fold<int>(
      0,
      (sum, reward) => sum + reward.points,
    );
    
    return OfferStatistics(
      completedCount: completed.length,
      totalEarnedPoints: totalEarned,
      pendingCount: pending.length,
      pendingPoints: pendingPoints,
    );
  }

  /// 클릭 추적
  Future<void> _trackClick(String userId, OfferwallOffer offer) async {
    // 실제로는 제공사 API 호출
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 분석 데이터 수집
    _analyticsData.add(ClickEvent(
      userId: userId,
      offerId: offer.id,
      provider: offer.provider,
      timestamp: DateTime.now(),
    ));
  }

  /// 콜백 서명 검증
  bool _verifyCallback(Map<String, dynamic> data) {
    // 실제로는 HMAC 등으로 서명 검증
    // 여기서는 간단히 필수 필드만 체크
    return data.containsKey('userId') &&
           data.containsKey('offerId') &&
           data.containsKey('timestamp');
  }

  /// 샘플 오퍼 로드
  void _loadSampleOffers() {
    _activeOffers.addAll([
      OfferwallOffer(
        id: 'offer_001',
        provider: 'adpopcorn',
        type: OfferType.appInstall,
        title: '쿠팡 앱 설치하고 첫 구매',
        description: '쿠팡 앱을 설치하고 10,000원 이상 첫 구매 시',
        iconUrl: 'https://example.com/coupang_icon.png',
        points: 3000,
        requirements: [
          '쿠팡 앱 신규 설치',
          '회원가입 완료',
          '10,000원 이상 첫 구매',
        ],
        deepLink: 'coupang://app',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
      OfferwallOffer(
        id: 'offer_002',
        provider: 'tnkfactory',
        type: OfferType.signup,
        title: '토스 가입하고 계좌 연결',
        description: '토스 신규 가입 후 계좌 1개 이상 연결',
        iconUrl: 'https://example.com/toss_icon.png',
        points: 2000,
        requirements: [
          '토스 신규 회원가입',
          '본인인증 완료',
          '은행 계좌 1개 이상 연결',
        ],
        deepLink: 'supertoss://signup',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
      OfferwallOffer(
        id: 'offer_003',
        provider: 'nas',
        type: OfferType.gameLevel,
        title: '리니지M 레벨 20 달성',
        description: '리니지M 설치 후 캐릭터 레벨 20 달성',
        iconUrl: 'https://example.com/lineagem_icon.png',
        points: 5000,
        requirements: [
          '리니지M 신규 설치',
          '캐릭터 생성',
          '레벨 20 달성 (약 3-5일 소요)',
        ],
        deepLink: 'lineagem://play',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ),
      OfferwallOffer(
        id: 'offer_004',
        provider: 'adpopcorn',
        type: OfferType.survey,
        title: '설문조사 참여 (10분)',
        description: '브랜드 인식도 설문조사 참여',
        iconUrl: 'https://example.com/survey_icon.png',
        points: 500,
        requirements: [
          '설문 끝까지 완료',
          '성실한 응답',
          '소요시간 약 10분',
        ],
        deepLink: 'https://survey.example.com/brand2024',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
      OfferwallOffer(
        id: 'offer_005',
        provider: 'tnkfactory',
        type: OfferType.creditCard,
        title: '삼성카드 신규 발급',
        description: '삼성카드 taptap 신규 발급 완료',
        iconUrl: 'https://example.com/samsung_card_icon.png',
        points: 10000,
        requirements: [
          '만 19세 이상',
          '삼성카드 신규 고객',
          '카드 발급 완료',
          '발급 후 1회 이상 사용',
        ],
        deepLink: 'samsungcard://apply',
        expiresAt: DateTime.now().add(const Duration(days: 60)),
        isHighValue: true,
      ),
      OfferwallOffer(
        id: 'offer_006',
        provider: 'nas',
        type: OfferType.subscription,
        title: '넷플릭스 1개월 구독',
        description: '넷플릭스 신규 가입 후 1개월 유지',
        iconUrl: 'https://example.com/netflix_icon.png',
        points: 4000,
        requirements: [
          '넷플릭스 신규 회원',
          '유료 플랜 가입',
          '1개월 구독 유지',
        ],
        deepLink: 'https://netflix.com/signup',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
    ]);
  }

  // 분석 데이터
  final List<ClickEvent> _analyticsData = [];
}

/// 오퍼월 제공사
class OfferwallProvider {
  final String name;
  final String apiKey;
  final String baseUrl;

  const OfferwallProvider({
    required this.name,
    required this.apiKey,
    required this.baseUrl,
  });
}

/// 오퍼월 광고
class OfferwallOffer {
  final String id;
  final String provider;
  final OfferType type;
  final String title;
  final String description;
  final String iconUrl;
  final int points;
  final List<String> requirements;
  final String deepLink;
  final DateTime expiresAt;
  final bool isActive;
  final bool isHighValue;

  OfferwallOffer({
    required this.id,
    required this.provider,
    required this.type,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.points,
    required this.requirements,
    required this.deepLink,
    required this.expiresAt,
    this.isActive = true,
    this.isHighValue = false,
  });
}

/// 오퍼 타입
enum OfferType {
  appInstall,    // 앱 설치
  signup,        // 회원가입
  purchase,      // 구매
  gameLevel,     // 게임 레벨 달성
  survey,        // 설문조사
  creditCard,    // 신용카드 발급
  subscription,  // 구독 서비스
  video,         // 동영상 시청
  social,        // SNS 활동
}

/// 오퍼 완료 결과
class OfferCompletionResult {
  final bool success;
  final int? points;
  final String? offerId;
  final String? error;

  OfferCompletionResult({
    required this.success,
    this.points,
    this.offerId,
    this.error,
  });
}

/// 대기 중인 보상
class PendingReward {
  final String userId;
  final String offerId;
  final int points;
  final DateTime startedAt;
  final DateTime expiresAt;

  PendingReward({
    required this.userId,
    required this.offerId,
    required this.points,
    required this.startedAt,
    required this.expiresAt,
  });
}

/// 오퍼 통계
class OfferStatistics {
  final int completedCount;
  final int totalEarnedPoints;
  final int pendingCount;
  final int pendingPoints;

  OfferStatistics({
    required this.completedCount,
    required this.totalEarnedPoints,
    required this.pendingCount,
    required this.pendingPoints,
  });
}

/// 클릭 이벤트
class ClickEvent {
  final String userId;
  final String offerId;
  final String provider;
  final DateTime timestamp;

  ClickEvent({
    required this.userId,
    required this.offerId,
    required this.provider,
    required this.timestamp,
  });
}