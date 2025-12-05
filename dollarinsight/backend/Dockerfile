# ==============================================
# Stage 1: Build Stage
# ==============================================
FROM gradle:8.5-jdk21 AS builder

WORKDIR /app

# Gradle 의존성 캐싱을 위해 build.gradle, settings.gradle 먼저 복사
COPY build.gradle settings.gradle ./
COPY gradle gradle

# 의존성 다운로드 (캐시 활용)
RUN gradle dependencies --no-daemon || true

# 소스 코드 복사
COPY src ./src

# 애플리케이션 빌드 (테스트 제외)
RUN gradle clean build -x test --no-daemon

# ==============================================
# Stage 2: Runtime Stage
# ==============================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# 필수 패키지 설치 (curl: 헬스체크용, tzdata: 타임존 설정용)
RUN apk add --no-cache curl tzdata

# 타임존 설정
ENV TZ=Asia/Seoul

# 애플리케이션 실행을 위한 non-root 사용자 생성
RUN addgroup -S spring && adduser -S spring -G spring

# 로그 디렉토리 생성
RUN mkdir -p /app/logs && chown -R spring:spring /app

# 빌드 스테이지에서 jar 파일 복사
COPY --from=builder /app/build/libs/*.jar app.jar

# 소유권 변경
RUN chown spring:spring app.jar

# non-root 사용자로 전환
USER spring:spring

# 포트 노출
EXPOSE 9090

# 헬스체크 설정
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:9090/actuator/health/liveness || exit 1

# JVM 옵션 설정
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# 애플리케이션 실행
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
