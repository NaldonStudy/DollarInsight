# 전술적 패턴: 엔티티, 리포지토리, 애플리케이션 서비스

## 레이어별 역할

### 도메인 (`*.domain`)

- **엔티티**: 식별자와 생명주기가 있는 객체(예: `User`, `UserWatchlist`, `ChatSession`). 비즈니스 규칙은 가능한 여기서 표현(예: `UserDevice.updatePush`).
- **값 객체 성격**: Enum·불변 값(`PlatformType`, `ChatTopicType` 등)은 엔티티와 함께 도메인 패키지에 둡니다.
- **리포지토리 인터페이스**: Spring Data `JpaRepository` 확장 인터페이스를 **도메인 패키지의 `repository`** 에 둡니다. 구현체는 Spring이 제공하므로, 헥사고날 용어로는 **아웃바운드 포트 = 인터페이스**, **어댑터 = Spring Data 구현**으로 보면 됩니다.

### 애플리케이션 (`*.application`)

- **유스케이스 오케스트레이션**: 한 요청에서 해야 할 일의 순서(트랜잭션 경계, 여러 리포지토리·도메인 서비스·인프라 호출).
- 네이밍: `AuthApplicationService`, `SessionService`, `UserService`, `ChatService`, `CompanyAnalysisService` 등 — 접미사 `Application`은 필수는 아니며, **패키지가 `application`이면 애플리케이션 서비스**로 간주합니다.

### 어댑터 — 웹 (`*.adapter.web`)

- **REST 컨트롤러**: HTTP 경로·상태코드·OpenAPI 메타데이터.
- **요청/응답 DTO**: JSON 스키마 전용 모델. 도메인 엔티티를 그대로 노출하지 않는 것이 이상적이며, 기기 목록 등은 `DeviceListItemResponse`처럼 **응답 전용 타입**으로 분리한 사례가 있습니다.

### 인프라 (`infra.*`)

- JWT·필터·Redis/Redisson 연계, Mongo 템플릿, 외부 REST 클라이언트.
- BC는 인프라 **구현 타입**이 아닌 **역할**(토큰 발급, 외부 호출)에 의존하도록 유지합니다.

## 애그리거트

엄격한 애그리거트 루트만 강제하지는 않았으나, 다음과 같이 **일관성 경계**를 두었습니다.

- **User** + `UserCredential` + OAuth 계정: 사용자 BC에서 트랜잭션으로 묶어 처리.
- **UserSession**: 리프레시·세션 무효화는 `SessionService`가 `auth.domain.session` 리포지토리와 조율.
- **ChatSession** + Mongo 메시지: PostgreSQL 메타와 Mongo 본문이 분리 저장 — 유스케이스에서 순서 보장.

## 도메인 서비스 vs 애플리케이션 서비스

- **도메인 서비스**: 둘 이상의 엔티티에 걸친 순수 규칙(한 엔티티에 넣기 애매할 때). 본 코드베이스는 대부분 엔티티 메서드 + 애플리케이션 서비스로 처리.
- **애플리케이션 서비스**: “이번 HTTP 요청에서의 시나리오” — `AuthApplicationService.signupAndIssue`가 대표적(회원 생성 → 액세스 발급 → 리프레시 저장).
