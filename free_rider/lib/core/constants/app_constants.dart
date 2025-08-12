/// FREERIDER 앱 상수 정의
class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'FREE RIDER';
  static const String appNameKr = '프리라이더';
  static const String appSlogan = '매일 무료로, 당당하게';
  static const String appDescription = '대한민국 교통비 제로 플랫폼';
  
  // API Endpoints
  static const String baseUrl = 'https://api.freerider.co.kr';
  static const String wsUrl = 'wss://ws.freerider.co.kr';
  
  // API Paths
  static const String authPath = '/auth';
  static const String userPath = '/users';
  static const String activityPath = '/activities';
  static const String pointPath = '/points';
  static const String cardPath = '/cards';
  static const String missionPath = '/missions';
  static const String adPath = '/ads';
  static const String challengePath = '/challenges';
  
  // Point System Constants
  static const int dailyTargetPoints = 1550; // 일일 목표 포인트 (서울 지하철 기본요금)
  static const int maxDailyPoints = 2000; // 일일 최대 획득 가능 포인트
  
  // Activity Point Limits - 일일 한도
  static const int walkingMaxPoints = 100; // 걷기 최대 100P (10,000걸음)
  static const int stairsMaxPoints = 50; // 계단 최대 50P (25층)
  static const int cyclingMaxPoints = 60; // 자전거 최대 60P (60분)
  static const int transitMaxPoints = 40; // 대중교통 최대 40P (4회)
  static const int runningMaxPoints = 40; // 러닝 최대 40P (20분)
  static const int meditationMaxPoints = 30; // 명상 최대 30P (15분)
  static const int voiceDiaryMaxPoints = 20; // 음성일기 최대 20P (1회)
  static const int callMaxPoints = 20; // 전화통화 최대 20P (20분)
  static const int adMaxPoints = 500; // 광고 시청 최대 500P
  static const int surveyMaxPoints = 100; // 설문 최대 100P (5회)
  static const int qrScanMaxPoints = 90; // QR 스캔 최대 90P (3회)
  static const int quizMaxPoints = 50; // 퀴즈 최대 50P (5문제)
  static const int newsMaxPoints = 25; // 뉴스 읽기 최대 25P (5기사)
  
  // Point Conversion Rates
  static const int pointsPerStep = 1; // 100걸음당 1P
  static const int stepsPerPoint = 100;
  static const int pointsPerFloor = 2; // 1층당 2P
  static const int pointsPerCyclingMinute = 1; // 자전거 1분당 1P
  static const int pointsPerTransitUse = 10; // 대중교통 1회당 10P
  static const int pointsPerRunningMinute = 2; // 러닝 1분당 2P
  
  // Time Bonuses
  static const double morningRushMultiplier = 2.0; // 아침 출근 시간 (7-9시) 2배
  static const double eveningRushMultiplier = 2.0; // 저녁 퇴근 시간 (18-20시) 2배
  static const double weekendMultiplier = 1.5; // 주말 1.5배
  
  // Sensor Update Intervals (milliseconds)
  static const int stepCounterInterval = 1000; // 1초
  static const int gpsUpdateInterval = 5000; // 5초
  static const int activityRecognitionInterval = 10000; // 10초
  
  // Cache Durations
  static const Duration cacheShortDuration = Duration(minutes: 5);
  static const Duration cacheMediumDuration = Duration(minutes: 30);
  static const Duration cacheLongDuration = Duration(hours: 2);
  static const Duration cacheVeryLongDuration = Duration(hours: 24);
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
  
  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 20;
  static const int phoneNumberLength = 11;
  static const int verificationCodeLength = 6;
  static const int nicknameMinLength = 2;
  static const int nicknameMaxLength = 12;
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserInfo = 'user_info';
  static const String keyFirstRun = 'first_run';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyNotificationEnabled = 'notification_enabled';
  static const String keyCardInfo = 'card_info';
  static const String keyLastSyncTime = 'last_sync_time';
  
  // Transport Card Types
  static const List<String> supportedCards = [
    'T-money',
    'Cashbee',
    '한꿈이카드',
    '레일플러스',
    '원패스',
  ];
  
  // Social Login Providers
  static const String providerKakao = 'kakao';
  static const String providerApple = 'apple';
  static const String providerGoogle = 'google';
  static const String providerNaver = 'naver';
  
  // Error Messages
  static const String errorNetwork = '네트워크 연결을 확인해주세요';
  static const String errorServer = '서버 오류가 발생했습니다';
  static const String errorAuth = '인증이 필요합니다';
  static const String errorPermission = '권한이 필요합니다';
  static const String errorUnknown = '알 수 없는 오류가 발생했습니다';
  
  // Success Messages  
  static const String successPointsEarned = '포인트를 획득했습니다!';
  static const String successCardCharged = '교통카드 충전이 완료되었습니다!';
  static const String successMissionComplete = '미션을 완료했습니다!';
  static const String successProfileUpdated = '프로필이 업데이트되었습니다';
  
  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  static final RegExp phoneRegex = RegExp(
    r'^010[0-9]{8}$',
  );
  static final RegExp nicknameRegex = RegExp(
    r'^[a-zA-Z0-9가-힣]{2,12}$',
  );
}