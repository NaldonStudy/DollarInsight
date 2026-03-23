# 기능 카탈로그: API → 유스케이스 → 도메인·인프라

HTTP 경로는 컨트롤러 클래스의 `@RequestMapping` + 메서드 매핑을 기준으로 정리했습니다. `X-Device-Id` 등 공통 헤더는 OpenAPI/Swagger 설명과 동일합니다.

---

## 1. user BC — [`user.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/user/adapter/web)

### AuthController (`/api/auth`)

| 메서드 | 경로 | 유스케이스(애플리케이션) | 도메인·외부 |
|--------|------|---------------------------|-------------|
| POST | `/api/auth/signup` | `AuthApplicationService.signupAndIssue` | `UserService.signup`, 기기·세션 `SessionService.issueRefreshAndStore`, JWT `TokenProvider` |
| POST | `/api/auth/login` | `AuthApplicationService.loginAndIssue` | `UserService` 로그인·액세스, `SessionService` |

### UserController (`/api/users`)

| 메서드 | 경로 | 유스케이스 | 도메인·연동 |
|--------|------|------------|-------------|
| GET | `/api/users/me` | `UserService.getByUuid` | `User` 엔티티 → `UserResponse` |
| PATCH | `/api/users/me/nickname` | `UserService.changeNickname` | 닉네임 유일성·`User` |
| PATCH | `/api/users/me/password` | `UserService.changePassword` | `UserCredential`, `PasswordEncoder` |
| GET | `/api/users/me/personas` | `PersonaQueryService` (persona BC) | 사용자-페르소나 조회 |
| PATCH | `/api/users/me/personas` | `UserPersonaService` | 페르소나 매핑 갱신 |
| DELETE | `/api/users/me` | `UserService` 탈퇴 흐름 | 소프트 삭제 등 |

### OAuthController (`/api/auth/oauth`)

| 메서드 | 경로 | 유스케이스 | 인프라 |
|--------|------|------------|--------|
| POST | `/api/auth/oauth/kakao` | `OAuthLoginService.loginWithKakao` | `infra.client.kakao`, 세션·토큰 |
| POST | `/api/auth/oauth/google` | `OAuthLoginService.loginWithGoogle` | `infra.client.google`, 세션·토큰 |

---

## 2. auth BC — [`auth.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/auth/adapter/web)

### SessionController (`/api/auth`)

| 메서드 | 경로 | 유스케이스 | 도메인·인프라 |
|--------|------|------------|---------------|
| POST | `/api/auth/refresh` | `SessionService.reissueAccessByRefresh` | `UserSession`, `RefreshTokenUtil`, JWT |
| POST | `/api/auth/logout` | `SessionService.logoutByDevice` | 세션 무효화, 선택적 리프레시 폐기 |
| GET | `/api/auth` | `SessionService.listSessions` | `auth.domain.session`, `SessionResponse` DTO |
| DELETE | `/api/auth/uuid/{sid}` | `SessionService.revokeByUuid` | 본인 세션만 |

**트랜잭션**: 세션 변경·갱신은 `SessionService` 구현체의 `@Transactional` 경계를 따릅니다.

---

## 3. device BC — [`device.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/device/adapter/web)

### DeviceController (`/api/devices`)

| 메서드 | 경로 | 유스케이스 | 도메인 |
|--------|------|------------|--------|
| GET | `/api/devices` | `DeviceService.list` | `UserDevice` → `DeviceListItemResponse`로 매핑(어댑터) |
| PATCH | `/api/devices/me/push` | `DeviceService.updatePushByDeviceId` | `UserDevice.updatePush` |
| DELETE | `/api/devices/by-device/{deviceId}` | `DeviceService.deleteByDeviceId` | `UserDeviceRepository` |

**다른 BC**: `UserRepository`로 활성 사용자 조회.

---

## 4. persona BC — [`persona.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/persona/adapter/web)

### PersonaController (`/api/personas`)

| 메서드 | 경로 | 유스케이스 | 도메인 |
|--------|------|------------|--------|
| GET | `/api/personas` | `PersonaQueryService` (목록) | `Persona`, `PersonaResponse` |

---

## 5. watchlist BC — [`watchlist.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/watchlist/adapter/web)

### WatchlistController (`/api/watchlist`)

| 메서드 | 경로 | 유스케이스 | 도메인·연동 |
|--------|------|------------|-------------|
| GET | `/api/watchlist` | `WatchlistService.getMyWatchlist` | `UserWatchlist`, `CompanyAnalysisQueryRepository`(자산·가격 메타) |
| POST | `/api/watchlist` | 관심 종목 추가 | 티커 검증, 중복 시 409 |
| DELETE | `/api/watchlist/{ticker}` | 삭제 | |
| GET | `/api/watchlist/{ticker}/status` | 포함 여부 등 | |

**BC 간**: `companyanalysis.domain.repository.CompanyAnalysisQueryRepository`를 통해 마스터·시세 정보 조회.

---

## 6. chat BC — [`chat.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/chat/adapter/web)

### ChatController (`/api/chat`)

| 메서드 | 경로 | 유스케이스(요약) | 저장·인프라 |
|--------|------|------------------|-------------|
| POST | `/api/chat/sessions` | `ChatService.createSession` | `ChatSession` JPA, 페르소나 |
| POST | `/api/chat/sessions/{sid}/messages` | 메시지 추가 | Mongo, FastAI 연동(구현 참조) |
| GET | `/api/chat/sessions` | 세션 목록 | |
| DELETE | `/api/chat/sessions/{sid}` | 세션 삭제 | |
| GET | `/api/chat/sessions/{sid}/stream` | SSE 스트림 | `infra.sse` |
| POST | `/api/chat/sessions/{sid}/interrupt` | 중단 | |
| POST | `/api/chat/sessions/{sid}/control/resume` | 재개 | |
| POST | `/api/chat/sessions/{sid}/control/pace` | 페이스 변경 | |
| GET | `/api/chat/sessions/{sid}/history` | 히스토리(커서) | |
| GET | `/api/chat/sessions/{sid}/history2` | 히스토리 변형 | |

**다른 BC**: `UserRepository`, `PersonaRepository`, Mongo `infra.mongo.chat`, 필요 시 FastAI `FastAiGateway`.

---

## 7. companyanalysis BC — [`companyanalysis.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/companyanalysis/adapter/web)

### CompanyAnalysisController (`/api/company-analysis`)

| 메서드 | 경로 | 유스케이스 | 데이터 |
|--------|------|------------|--------|
| GET | `/dashboard` | `CompanyAnalysisService.getDashboard` | 지수·뉴스·데일리 픽(Mongo 등) |
| GET | `/search` | `searchAssets` | DB ILIKE 검색 |
| GET | `/assets` | `listAssets` | `assets_master` |
| GET | `/{ticker}` | 상세 번들 | 가격·지표·뉴스 |
| GET | `/news` | 뉴스 목록 | |
| GET | `/news/{newsId}` | 뉴스 상세 | |

**인프라**: `CompanyAnalysisQueryRepository`, Mongo 문서, `FastAiGateway`(해당 분석 호출 시).

---

## 8. common BC — [`common.adapter.web`](../../backend/src/main/java/com/ssafy/b205/backend/common/adapter/web)

### PingController (`/api`)

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/public/ping` | 무인증 헬스 |
| GET | `/api/ping` | 인증 필요 핑 |
| POST | `/api/public/dev/token` | 개발용 토큰(프로파일 제한) |

---

## 클라이언트·AI 서비스 연동(문서용)

| 소비자 | 호출 대상(예) | 비고 |
|--------|----------------|------|
| Flutter 앱 | `/api/auth/*`, `/api/users/*`, `/api/company-analysis/*`, `/api/chat/*` | `BASE_URL` 및 Bearer·헤더 |
| FastAPI(ai-service) | 백엔드가 **클라이언트**로 FastAI 호출 | `infra.client.fastai` |

---

## 보안(참고)

`SecurityConfig`에서 공개 경로는 `/api/auth/signup`, `/login`, `/refresh`, `/api/auth/oauth/**`, 문서·actuator 등입니다. 상세는 [`infra/security/SecurityConfig.java`](../../backend/src/main/java/com/ssafy/b205/backend/infra/security/SecurityConfig.java)를 참고하세요.
