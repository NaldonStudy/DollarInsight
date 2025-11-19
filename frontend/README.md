# 🦉 Dollar Insight - Frontend
미국 주식 투자 입문자를 위한 AI 기반 종목 분석·뉴스 요약·페르소나 챗 서비스를 제공하는  
**Dollar Insight 모바일 앱(Flutter) 프론트엔드(Frontend) 레포지토리입니다.**

## 📦 기술스택 & 버전
| 항목 | 버전 |
|------|------|
| **Flutter SDK** | 3.24.x (environment: sdk: ^3.9.2 사용) |
| **Dart** | ^3.9.2 |
| **State Management** | Provider |
| **Routing** | go_router ^13.0.0 |
| **Network** | dio ^5.4.0 |
| **Local Storage** | flutter_secure_storage ^9.2.2 |
| **OAuth** | google_sign_in ^7.2.0, kakao_flutter_sdk_user ^1.9.0 |
| **Build & Serialization** | build_runner, json_serializable |
| **Chart** | fl_chart ^0.69.0 |
| **Env 관리** | flutter_dotenv ^5.1.0 |
| **ETC** | intl, url_launcher, shared_preferences |

## 📁 폴더구조
```
lib/
├── core/
│ ├── constants/                # 공통 상수 (AppSpacing 등)
│ ├── services/                 # 서비스 레이어(예: API Wrapper 등)
│ └── utils/                    # 공통 유틸 함수(Device ID 등)
│
├── data/
│ ├── datasources/
│ │ ├── local/                  # SecureStorage 등 로컬 저장소
│ │ └── remote/                 # Dio 기반 API 통신
│ ├── models/                   # JSON Serializable 모델 정의
│ └── repositories/             # Repository 패턴 구현
│
├── presentation/
│ ├── providers/                # Provider 상태관리
│ ├── screens/
│ │ ├── auth/                   # 로그인/회원가입
│ │ ├── chat/                   # AI 페르소나 채팅
│ │ ├── company/                # 종목 분석
│ │ ├── etf/                    # ETF
│ │ ├── main/                   # 홈 / 메인페이지 
│ │ ├── mypage/                 # 마이페이지
│ │ ├── news/                   # 뉴스 상세/목록
│ │ ├── onboarding/             # 온보딩
│ │ ├── splash/                 # 스플래시
│ │ └── test_chat_screen.dart
│ │
│ ├── widgets/
│ │ ├── chat/                   # 채팅 위젯
│ │ ├── common/                 # 공통 위젯 (버튼, 텍스트필드 등)
│ │ ├── company/                # 종목 관련 위젯
│ │ ├── main/                   # 메인 홈 UI 위젯
│ │ ├── persona/                # 페르소나 관련 UI
│ │ └── signup/                 # 회원가입 관련 컴포넌트
│ │
│ └── routes/                   # go_router 라우트 정의
│
└── main.dart                   # 앱 진입점
```

## ▶️ 실행방법 

### 1. 패키지 설치
```
flutter pub get
```
### 2. 환경 변수(.env) 설정
```
BASE_URL=
GOOGLE_ANDROID_CLIENT_ID=
KAKAO_NATIVE_APP_KEY=
```
### 3. 앱 실행
```
flutter run
```
### 4. JSON Serializable 생성
```
flutter pub run build_runner build --delete-conflicting-outputs
```

## 👨‍💻 Frontend 개발자
| 역할 | 이름                  |
|------|---------------------|
| Frontend Developer | 김준혁 (Kim Jun Hyeok) |
| Frontend Developer | 임주빈 (Im Ju Bin)     |


## 📌 참고
- 본 프로젝트는 Flutter 기반의 모바일 전용 서비스입니다.
- .env 환경 변수 파일은 Git에 포함되지 않습니다.

#### Copyright 2025. **SSAFY** All Rights Reserved.