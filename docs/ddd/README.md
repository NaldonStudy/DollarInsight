# Dollar Insight 백엔드 — DDD 적용 문서

이 디렉터리는 Spring Boot 백엔드에 **도메인 주도 설계(DDD)** 관점의 패키지 구조를 적용한 결과와, 용어·바운디드 컨텍스트·기능 매핑을 정리합니다.

## 적용 범위

- **포함**: [`backend/src/main/java/com/ssafy/b205/backend`](../../backend/src/main/java/com/ssafy/b205/backend) 이하 소스 트리, 바운디드 컨텍스트별 `adapter.web` / `application` / `domain` 레이어.
- **문서만 연동**: Flutter 앱·FastAPI(ai-service)는 소스 트리를 바꾸지 않으며, [기능 카탈로그](04-feature-catalog.md)에서 API·외부 연동 관점으로만 언급합니다.

## 문서 목차

| 문서 | 내용 |
|------|------|
| [01-strategic-design.md](01-strategic-design.md) | 바운디드 컨텍스트, 컨텍스트 맵, 공유 커널 |
| [02-tactical-patterns.md](02-tactical-patterns.md) | 엔티티, 리포지토리(포트), 애플리케이션 서비스 |
| [03-package-and-layers.md](03-package-and-layers.md) | 패키지 트리, 레이어별 책임 |
| [04-feature-catalog.md](04-feature-catalog.md) | API·유스케이스·도메인·인프라 상세 매핑 |
| [05-ddd-compliance-evaluation.md](05-ddd-compliance-evaluation.md) | 백엔드 DDD 준수 여부 평가(전략·전술·완화 지점) |

## 빌드 참고

Gradle 및 Spring Boot 3.x는 **JDK 17 이상**이 필요합니다. 로컬에서 `./gradlew test` 실행 전 `JAVA_HOME`을 확인하세요.
