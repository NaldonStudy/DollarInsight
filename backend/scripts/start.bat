@echo off
REM Docker Compose 전체 스택 시작 스크립트 (Windows)

echo ================================================
echo Dollar Insight Backend Stack 시작
echo ================================================

REM .env 파일 확인
IF NOT EXIST .env (
    echo WARNING: .env 파일이 없습니다. .env.template을 복사합니다.
    copy .env.template .env
    echo SUCCESS: .env 파일이 생성되었습니다. 필요시 수정해주세요.
    echo.
)

REM Docker Compose 시작
echo 서비스 시작 중...
docker-compose up -d

IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: 서비스 시작 실패
    pause
    exit /b 1
)

echo.
echo 서비스가 준비될 때까지 대기 중...
timeout /t 10 /nobreak >nul

echo.
echo 서비스 상태:
docker-compose ps

echo.
echo ================================================
echo SUCCESS: 모든 서비스가 시작되었습니다!
echo.
echo 접속 정보:
echo   - Backend API: http://localhost:8080
echo   - Health Check: http://localhost:8080/actuator/health
echo   - PostgreSQL: localhost:5432
echo   - MongoDB: localhost:27017
echo   - Redis: localhost:6379
echo.
echo 로그 확인:
echo   docker-compose logs -f backend
echo.
echo 서비스 중지:
echo   scripts\stop.bat
echo ================================================

pause
