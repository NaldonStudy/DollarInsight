# 패키지 구조와 레이어

## 최상위 구조

```
com.ssafy.b205.backend
├── BackendApplication.java
├── auth/
│   ├── adapter/web/          # SessionController, DTO
│   ├── application/          # AuthApplicationService, SessionService, OAuthLoginService
│   └── domain/session/       # UserSession 엔티티·리포지토리 (인증 하위 도메인)
├── user/
│   ├── adapter/web/          # AuthController, UserController, OAuthController, API DTO
│   ├── application/          # UserService
│   └── domain/entity|repository/
├── device/
│   ├── adapter/web/
│   ├── application/
│   └── domain/
├── persona/
├── watchlist/
├── chat/
├── companyanalysis/
├── common/adapter/web/
├── config/
├── infra/
└── support/
```

## 레이어 책임 표

| 패키지 접미사 | 역할 | 의존 방향 |
|---------------|------|-----------|
| `*.adapter.web` | Spring MVC, DTO, Swagger | → `*.application`, (매핑 시) `*.domain` |
| `*.application` | 유스케이스, `@Transactional` 경계 | → `*.domain`, `infra.*` |
| `*.domain` | 엔티티, 리포지토리 인터페이스 | → (동일 BC 내) 엔티티 간; 다른 BC 엔티티 직접 참조는 최소화 |
| `infra.*` | DB 구현 세부, 보안, 외부 API | 애플리케이션/도메인이 **추상화에 의존** |

## 세션 패키지를 `auth` 아래에 둔 이유

`UserSession`은 **리프레시 토큰·로그아웃·세션 목록**과 직결되므로 인증·세션 BC의 일부로 보는 것이 자연스럽습니다. 패키지 경로는 `auth.domain.session.entity`, `auth.domain.session.repository` 입니다.

## Spring Boot 컴포넌트 스캔

`@SpringBootApplication`이 `com.ssafy.b205.backend`에 있으므로, 위 모든 하위 패키지의 `@Service`, `@RestController`, JPA 엔티티가 스캔됩니다. 별도 `@EntityScan` 변경은 필요 없습니다.
