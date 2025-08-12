# CLAUDE.md - FREERIDER 프로젝트 명령 지침서

## 🎯 프로젝트 개요

**FREERIDER (프리라이더)**는 한국인을 위한 일일 무료 교통비 제공 모바일 애플리케이션입니다.
- **비전**: "매일 무료로, 당당하게 - 대한민국 교통비 제로 플랫폼"
- **목표**: 일일 교통비 1,550원을 포인트로 제공하여 국민의 교통비 부담 제로화
- **대상**: 수도권 20-39세 직장인 및 대학생 (일일 대중교통 이용자)

## 📁 핵심 프로젝트 문서

### 필수 참조 문서
- **freerider-prd.md**: 제품 요구사항 명세서 (기능, API, 비즈니스 모델)
- **freerider-flutter-uiux.md**: Flutter UI/UX 구현 가이드 (디자인 시스템, 위젯, 화면 구현)
- **freerider-brand.md**: 브랜드 전략서 (비주얼 아이덴티티, 마케팅 가이드라인)
- **quality.txt**: Flutter 앱 품질 관리 가이드 (테스트, 성능, 보안 기준)

## 🛠️ 개발 환경 설정

### Flutter 프로젝트 구조
```
free_rider/
├── lib/
│   ├── core/         # Constants, themes, utilities, services
│   ├── data/         # Models, repositories, providers  
│   ├── presentation/ # Screens, widgets, animations
│   └── routes/       # Navigation configuration
```

### 핵심 의존성 패키지
- **State Management**: flutter_riverpod ^2.4.0
- **Navigation**: go_router ^12.0.0
- **Animations**: flutter_animate ^4.3.0, lottie ^2.7.0
- **Native Features**: flutter_nfc_kit, flutter_local_notifications
- **Backend**: dio ^5.4.0, retrofit ^4.0.0

## 💻 자주 사용하는 개발 명령어

### Flutter Development
```bash
# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run app in debug mode
flutter run

# Run app with specific device
flutter run -d <device_id>

# Build APK for Android
flutter build apk --release

# Build iOS app
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### Platform-Specific Commands
```bash
# iOS setup (macOS only)
cd ios && pod install

# Android gradle sync
cd android && ./gradlew sync
```

## 🏗️ 아키텍처 개요

### 핵심 기술 스택
- **Frontend**: Flutter 3.x cross-platform framework
- **State Management**: Riverpod 2.0 for reactive state management
- **Backend**: Node.js with NestJS microservices (AWS serverless)
- **Database**: PostgreSQL + Redis + DynamoDB
- **Real-time**: WebSocket for live point updates
- **ML**: TensorFlow.js for activity pattern recognition

### 핵심 기능 아키텍처

1. **Point Accumulation System**
   - Movement tracking (walking, cycling, transit)
   - Voice activities (calls, voice diary)
   - Visual activities (ad viewing, surveys)
   - Cognitive activities (quizzes, news reading)
   - Real-time sensor data processing

2. **Transportation Card Integration**
   - Direct charging to T-money, Cashbee, etc.
   - Mobile wallet integration (Samsung Pay, Apple Pay)
   - Automatic charging at 1,550 points

3. **Sensor System**
   - Accelerometer for step counting
   - GPS for location/movement tracking
   - Microphone for voice activities
   - Camera for QR scanning
   - Battery optimization with multiple modes

### API 구조

앱은 다음 주요 API를 통해 백엔드 서비스와 통신합니다:
- **Activity Tracking API**: 모든 사용자 활동 기록 및 포인트 계산
- **Realtime Points Service**: WebSocket 기반 실시간 포인트 업데이트
- **Transport Card Service**: 교통카드 충전 트랜잭션 처리
- **ML Activity Recognition**: 센서 데이터로부터 사용자 활동 분류

## 🎨 디자인 시스템

### 컬러 팔레트
- **Primary Green** (#00FF88): Freedom, action
- **Seoul Black** (#0A0A0A): Premium feel
- **Reward Orange** (#FF6B35): Rewards, celebration
- **Subway Blue** (#0066FF): Trust, stability

### 타이포그래피
- **Font**: Pretendard (Korean/English)
- **Hierarchy**: Display > Headlines (h1-h3) > Body > Caption

### 반응형 디자인
- Base design size: 390x844 (iPhone 14 Pro)
- Uses flutter_screenutil for responsive scaling
- Mobile-first, portrait orientation only

## 🧪 테스트 전략

### Unit Testing
- Test models, repositories, and business logic
- Use mockito for dependency mocking

### Widget Testing  
- Test individual widgets and screens
- Verify UI states and interactions

### Integration Testing
- Test complete user flows
- Verify API integrations

## ⚠️ 중요 고려사항

### 개인정보 보호 및 보안
- All sensor data is anonymized
- Card numbers encrypted with AES-256
- PCI DSS compliance for payment data
- Location data processed in segments only

### 성능 목표
- Battery usage target: <5% daily
- API response time: <200ms
- App crash rate: <0.5%
- Charging success rate: >99.5%

### 한국 시장 특성
- Primary target: 25-39 year old office workers in Seoul/Gyeonggi
- Peak usage times: 7-9 AM, 6-8 PM (commute hours)
- Integration with Korean transport cards (T-money, Cashbee)
- Korean language as primary, English as secondary

## 📋 개발 작업 지침

### 필수 준수사항
1. **코드 패턴**: 새 기능 구현 전 기존 코드 패턴과 컨벤션 확인
2. **프로젝트 구조**: 일관성을 위해 정해진 프로젝트 구조 준수
3. **상태 관리**: setState 대신 Riverpod providers 사용
4. **에러 처리**: 한국어로 사용자 친화적인 에러 메시지 구현
5. **테스트**: iOS/Android 모두에서 테스트 후 완료
6. **국제화**: intl 패키지를 사용한 텍스트 국제화
7. **품질 기준**: quality.txt의 품질 기준 준수 (코드 커버리지 85% 이상)

## 💡 핵심 비즈니스 로직

### 포인트 계산 시스템
- Daily cap: 1,550 points (exact fare for Seoul metro)
- Activity limits prevent abuse (e.g., max 100P from 10,000 steps)
- Time bonuses during commute hours (2x multiplier)
- Weather bonuses for harsh conditions

### 사용자 여정
1. Onboarding with card registration
2. Daily activity tracking
3. Point accumulation through various activities  
4. Automatic/manual card charging at 1,550P
5. Push notification confirmation

## 🚀 구현 우선순위

### Phase 1: MVP (필수 기능)
1. **사용자 인증**: 회원가입/로그인 (카카오, 애플)
2. **온보딩**: 교통카드 등록 프로세스
3. **메인 대시보드**: 포인트 현황, 일일 미션
4. **활동 추적**: 걷기, 대중교통 이용 감지
5. **광고 시청**: 리워드 광고 시스템
6. **포인트 충전**: 교통카드 자동 충전

### Phase 2: 확장 기능
1. **소셜 기능**: 친구 초대, 리더보드
2. **챌린지 시스템**: 주간/월간 챌린지
3. **상점**: 포인트로 구매 가능한 아이템
4. **알림**: 푸시 알림, 인앱 알림

### Phase 3: 고도화
1. **ML 기반 활동 인식**: TensorFlow.js 통합
2. **실시간 업데이트**: WebSocket 연결
3. **배터리 최적화**: 백그라운드 작업 최적화
4. **A/B 테스팅**: 기능 실험 플랫폼

## 📝 구현 명령 예시

### 화면 구현 요청 시
```
"freerider-flutter-uiux.md의 [화면명] 섹션을 참고하여 구현해주세요"
예: "온보딩 화면을 구현해주세요" → Section 4.1 Onboarding Screens 참조
```

### 기능 구현 요청 시
```
"freerider-prd.md의 [기능명] 섹션을 기반으로 구현해주세요"
예: "포인트 적립 시스템을 구현해주세요" → Section 3.1 포인트 적립 시스템 참조
```

### 품질 검증 요청 시
```
"quality.txt의 기준에 따라 [검증 항목]을 확인해주세요"
예: "코드 품질을 검사해주세요" → quality.txt의 코드 품질 검사 섹션 참조
```

## 🔧 개발 도구 및 환경

### 필수 설치 도구
- Flutter SDK 3.x
- Android Studio / Xcode
- VS Code with Flutter extensions
- Git

### 권장 VS Code Extensions
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets
- Error Lens
- GitLens

## 📊 품질 관리 체크리스트

### 코드 작성 시
- [ ] Lint 규칙 준수 (flutter analyze 통과)
- [ ] 코드 포맷팅 (dart format)
- [ ] 의미있는 변수/함수명 사용
- [ ] 주석 및 문서화

### 기능 구현 완료 시
- [ ] 단위 테스트 작성 (커버리지 85% 이상)
- [ ] 위젯 테스트 작성
- [ ] iOS/Android 실기기 테스트
- [ ] 성능 프로파일링 (60fps 유지)
- [ ] 메모리 누수 체크

### PR 제출 전
- [ ] 모든 테스트 통과
- [ ] 코드 리뷰 체크리스트 확인
- [ ] CHANGELOG 업데이트
- [ ] 문서 업데이트

## 🌐 참조 링크

- **프로젝트 문서**: /FREERIDER/*.md
- **Flutter 공식 문서**: https://docs.flutter.dev
- **Riverpod 문서**: https://riverpod.dev
- **Material Design 3**: https://m3.material.io