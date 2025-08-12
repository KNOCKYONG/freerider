# FREE RIDER - 대한민국 교통비 제로 플랫폼

<p align="center">
  <img src="assets/logo.png" width="200" alt="FREE RIDER Logo">
</p>

<p align="center">
  <strong>매일 무료로, 당당하게</strong><br>
  일일 교통비 1,550원을 무료로 제공하는 스마트 모빌리티 플랫폼
</p>

## 📱 프로젝트 소개

**FREE RIDER**는 일상 활동(걷기, 광고 시청, 미션 수행)을 통해 포인트를 적립하고, 
하루 교통비 1,550원을 무료로 충전받을 수 있는 혁신적인 모바일 애플리케이션입니다.

### 🎯 핵심 가치
- **사용자**: 하루 3-5분 투자로 일일 교통비 무료
- **광고주**: 타겟팅된 20-40대 활성 사용자에게 효과적인 광고 노출
- **제휴사**: 신규 고객 유입 및 데이터 기반 마케팅 기회

## 🚀 주요 기능

### 포인트 적립 시스템
- **🚶 이동 포인트**: 걷기, 계단 오르기, 자전거, 대중교통 이용
- **💨 호흡 포인트**: 명상, 심호흡 운동, 수면 추적
- **🗣️ 음성 포인트**: 음성 일기, 노래방, 전화 통화
- **👁️ 시각 포인트**: 광고 시청, 설문, 제품 사진, QR 스캔
- **🧠 인지 포인트**: 퀴즈, 뉴스 읽기, 학습 콘텐츠

### 교통카드 자동 충전
- T-money, Cashbee 등 주요 교통카드 지원
- 1,550 포인트 도달 시 자동 충전
- Samsung Pay, Apple Pay 연동

## 🛠️ 기술 스택

### Frontend
- **Framework**: Flutter 3.x
- **State Management**: Riverpod 2.0
- **Navigation**: GoRouter
- **UI/UX**: Material Design 3

### Backend
- **Server**: Node.js with NestJS
- **Database**: PostgreSQL + Redis + DynamoDB
- **Real-time**: WebSocket
- **ML**: TensorFlow.js

## 📂 프로젝트 구조

```
free_rider/
├── lib/
│   ├── core/         # 상수, 테마, 유틸리티, 서비스
│   ├── data/         # 모델, 리포지토리, 프로바이더
│   ├── presentation/ # 화면, 위젯, 애니메이션
│   └── routes/       # 네비게이션 설정
├── assets/          # 이미지, 폰트, 애니메이션
└── test/           # 테스트 파일
```

## 🚦 시작하기

### 필수 요구사항
- Flutter SDK 3.x 이상
- Dart SDK 3.0 이상
- Android Studio / Xcode
- Git

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/KNOCKYONG/freerider.git

# 프로젝트 디렉토리로 이동
cd freerider/free_rider

# 의존성 설치
flutter pub get

# 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run
```

## 📱 지원 플랫폼
- iOS 12.0+
- Android 6.0+ (API level 23)

## 🎨 디자인 시스템

### 컬러 팔레트
- **Primary Green** (#00FF88): 자유, 행동
- **Seoul Black** (#0A0A0A): 프리미엄
- **Reward Orange** (#FF6B35): 보상, 축하
- **Subway Blue** (#0066FF): 신뢰, 안정

### 타이포그래피
- **Font**: Pretendard (한글/영문)
- **Hierarchy**: Display > Headlines > Body > Caption

## 📊 품질 기준
- 코드 커버리지: ≥85%
- 앱 시작 시간: <2초
- 크래시율: <0.1%
- 프레임율: 60fps

## 📝 문서
- [제품 요구사항 명세서](freerider-prd.md)
- [Flutter UI/UX 가이드](freerider-flutter-uiux.md)
- [브랜드 전략서](freerider-brand.md)
- [품질 관리 가이드](quality.txt)

## 🤝 기여하기
프로젝트 기여를 환영합니다! PR을 제출하기 전에 다음을 확인해주세요:
- [ ] 모든 테스트 통과
- [ ] 코드 포맷팅 (`dart format`)
- [ ] Lint 규칙 준수 (`flutter analyze`)

## 📄 라이선스
Copyright © 2024 FREE RIDER. All rights reserved.

## 📞 문의
- Email: contact@freerider.co.kr
- Website: https://freerider.co.kr
