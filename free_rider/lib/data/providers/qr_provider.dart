import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';

// QR State Provider
final qrStateProvider = StateNotifierProvider<QRNotifier, QRState>((ref) {
  return QRNotifier();
});

// QR Scan Result Model
class QRScanResult {
  final bool success;
  final int points;
  final String? storeName;
  final String? message;
  final DateTime timestamp;

  QRScanResult({
    required this.success,
    this.points = 0,
    this.storeName,
    this.message,
    required this.timestamp,
  });
}

// QR History Model
class QRHistory {
  final String id;
  final String code;
  final String storeName;
  final int points;
  final Position? location;
  final DateTime scannedAt;

  QRHistory({
    required this.id,
    required this.code,
    required this.storeName,
    required this.points,
    this.location,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'storeName': storeName,
      'points': points,
      'location': location != null
          ? {
              'latitude': location!.latitude,
              'longitude': location!.longitude,
            }
          : null,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory QRHistory.fromJson(Map<String, dynamic> json) {
    return QRHistory(
      id: json['id'],
      code: json['code'],
      storeName: json['storeName'],
      points: json['points'],
      location: json['location'] != null
          ? Position(
              latitude: json['location']['latitude'],
              longitude: json['location']['longitude'],
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            )
          : null,
      scannedAt: DateTime.parse(json['scannedAt']),
    );
  }
}

// QR State
class QRState {
  final int todayScans;
  final int todayPoints;
  final List<QRHistory> scanHistory;
  final Set<String> scannedCodes;
  final DateTime? lastScanTime;
  final bool isProcessing;

  QRState({
    this.todayScans = 0,
    this.todayPoints = 0,
    this.scanHistory = const [],
    Set<String>? scannedCodes,
    this.lastScanTime,
    this.isProcessing = false,
  }) : scannedCodes = scannedCodes ?? {};

  QRState copyWith({
    int? todayScans,
    int? todayPoints,
    List<QRHistory>? scanHistory,
    Set<String>? scannedCodes,
    DateTime? lastScanTime,
    bool? isProcessing,
  }) {
    return QRState(
      todayScans: todayScans ?? this.todayScans,
      todayPoints: todayPoints ?? this.todayPoints,
      scanHistory: scanHistory ?? this.scanHistory,
      scannedCodes: scannedCodes ?? this.scannedCodes,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  bool get canScanMore => todayScans < 3;
}

// QR Notifier
class QRNotifier extends StateNotifier<QRState> {
  QRNotifier() : super(QRState());

  // Mock 제휴 매장 데이터
  final Map<String, Map<String, dynamic>> _partnerStores = {
    'STORE_GS25_001': {'name': 'GS25 강남역점', 'points': 30},
    'STORE_CU_002': {'name': 'CU 서울역점', 'points': 30},
    'STORE_SEVEN_003': {'name': '세븐일레븐 삼성점', 'points': 30},
    'STORE_EMART24_004': {'name': '이마트24 광화문점', 'points': 30},
    'STORE_MINISTOP_005': {'name': '미니스톱 신촌점', 'points': 30},
    'CAFE_STARBUCKS_001': {'name': '스타벅스 강남R점', 'points': 40},
    'CAFE_TWOSOME_002': {'name': '투썸플레이스 역삼점', 'points': 40},
    'REST_SUBWAY_001': {'name': '써브웨이 강남점', 'points': 35},
    'REST_BURGERKING_002': {'name': '버거킹 서울역점', 'points': 35},
  };

  Future<QRScanResult> processQRCode(String code) async {
    // 이미 처리 중이면 무시
    if (state.isProcessing) {
      return QRScanResult(
        success: false,
        message: '처리 중입니다. 잠시 기다려주세요.',
        timestamp: DateTime.now(),
      );
    }

    state = state.copyWith(isProcessing: true);

    try {
      // 일일 제한 확인
      if (state.todayScans >= 3) {
        return QRScanResult(
          success: false,
          message: '오늘의 QR 스캔 횟수를 모두 사용했습니다',
          timestamp: DateTime.now(),
        );
      }

      // 중복 스캔 확인
      if (state.scannedCodes.contains(code)) {
        return QRScanResult(
          success: false,
          message: '이미 스캔한 QR 코드입니다',
          timestamp: DateTime.now(),
        );
      }

      // 제휴 매장 확인
      final storeData = _partnerStores[code];
      if (storeData == null) {
        // 유효한 QR 코드 형식 확인 (예: STORE_로 시작)
        if (code.startsWith('STORE_') || 
            code.startsWith('CAFE_') || 
            code.startsWith('REST_')) {
          return QRScanResult(
            success: false,
            message: '제휴되지 않은 매장입니다',
            timestamp: DateTime.now(),
          );
        }
        return QRScanResult(
          success: false,
          message: '유효하지 않은 QR 코드입니다',
          timestamp: DateTime.now(),
        );
      }

      // 위치 확인 (선택적)
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // 위치 정보 없이도 진행
        print('Location error: $e');
      }

      // QR 스캔 기록 생성
      final history = QRHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        code: code,
        storeName: storeData['name'],
        points: storeData['points'],
        location: currentPosition,
        scannedAt: DateTime.now(),
      );

      // 상태 업데이트
      state = state.copyWith(
        todayScans: state.todayScans + 1,
        todayPoints: state.todayPoints + storeData['points'],
        scanHistory: [...state.scanHistory, history],
        scannedCodes: {...state.scannedCodes, code},
        lastScanTime: DateTime.now(),
        isProcessing: false,
      );

      return QRScanResult(
        success: true,
        points: storeData['points'],
        storeName: storeData['name'],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      return QRScanResult(
        success: false,
        message: '오류가 발생했습니다: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  void resetDaily() {
    state = QRState(
      scanHistory: state.scanHistory,
      scannedCodes: state.scannedCodes,
    );
  }

  List<QRHistory> getTodayHistory() {
    final now = DateTime.now();
    return state.scanHistory.where((history) {
      return history.scannedAt.year == now.year &&
             history.scannedAt.month == now.month &&
             history.scannedAt.day == now.day;
    }).toList();
  }
}