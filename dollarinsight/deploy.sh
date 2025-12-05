#!/bin/bash

################################################################################
# Dollar In$ight - Deployment Script (Optimized)
# 
# This script handles the deployment of Dollar In$ight services
# Uses Docker Hub images (no local build required)
# Only restarts application services (backend, ai-service)
# Keeps DB, Nginx and admin tools running
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="/opt/S13P31B205"
BACKUP_DIR="${DEPLOY_DIR}/backups"
MAX_BACKUPS=5
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Application services to update (DB, nginx, 관리 도구 제외)
APP_SERVICES="backend ai-service"

# Airflow 관련 설정
# Note: AI_airflow 폴더가 없어도 배포는 정상 진행됩니다 (경고만 표시)
# AI 팀원이 나중에 폴더를 추가하면 자동으로 Airflow도 배포됩니다
AIRFLOW_DIR="${DEPLOY_DIR}/ai-service/AI_airflow"
AIRFLOW_COMPOSE_FILE="docker-compose-airflow.yml"
AIRFLOW_SERVICES="airflow-webserver airflow-scheduler airflow-worker airflow-init"

# Logging
LOG_FILE="${DEPLOY_DIR}/deploy.log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root or with sudo
check_permissions() {
    if ! docker info > /dev/null 2>&1; then
        error "Cannot connect to Docker daemon. Please ensure:\n  1. Docker is running\n  2. Current user is in 'docker' group: sudo usermod -aG docker \$USER"
    fi
}

# Create necessary directories
create_directories() {
    log "Creating directories..."
    
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "Directories created ✓"
}

# Backup current deployment
backup_current_deployment() {
    if [ -d "$DEPLOY_DIR" ] && [ -f "$DEPLOY_DIR/$COMPOSE_FILE" ]; then
        log "Creating backup of current deployment..."
        
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_path="$BACKUP_DIR/backup_$timestamp"
        
        mkdir -p "$backup_path"
        
        # Backup docker compose.yml and .env files
        cp -r "$DEPLOY_DIR/$COMPOSE_FILE" "$backup_path/" 2>/dev/null || true
        cp -r "$DEPLOY_DIR/.env" "$backup_path/" 2>/dev/null || true
        cp -r "$DEPLOY_DIR/backend/.env" "$backup_path/backend.env" 2>/dev/null || true
        cp -r "$DEPLOY_DIR/ai-service/.env" "$backup_path/ai-service.env" 2>/dev/null || true
        
        # Backup Airflow configuration if exists
        if [ -d "$AIRFLOW_DIR" ] && [ -f "$AIRFLOW_DIR/$AIRFLOW_COMPOSE_FILE" ]; then
            mkdir -p "$backup_path/airflow"
            cp -r "$AIRFLOW_DIR/$AIRFLOW_COMPOSE_FILE" "$backup_path/airflow/" 2>/dev/null || true
            cp -r "$AIRFLOW_DIR/.env" "$backup_path/airflow/.env" 2>/dev/null || true
            log "Airflow configuration backed up ✓"
        fi
        
        log "Backup created at: $backup_path ✓"
        
        # Clean old backups
        cleanup_old_backups
    else
        log "No existing deployment to backup"
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    local backup_count=$(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        log "Cleaning up old backups (keeping last $MAX_BACKUPS)..."
        ls -1dt "$BACKUP_DIR"/backup_* | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -rf
        log "Old backups cleaned up ✓"
    fi
}

# Pull latest Docker images (애플리케이션 서비스만)
pull_images() {
    log "Pulling latest Docker images from Docker Hub..."
    info "Target services: $APP_SERVICES + Airflow"
    
    cd "$DEPLOY_DIR"
    
    # .env 파일 확인
    if [ ! -f backend/.env ] || [ ! -f ai-service/.env ]; then
        error "Environment files not found!\n  Please create:\n  - $DEPLOY_DIR/backend/.env\n  - $DEPLOY_DIR/ai-service/.env"
    fi
    
    # 애플리케이션 서비스만 이미지 pull
    if ! docker compose pull $APP_SERVICES; then
        error "Failed to pull Docker images\n  Check:\n  1. Internet connection\n  2. Docker Hub image availability\n  3. docker-compose.yml configuration"
    fi
    
    log "Application Docker images pulled successfully ✓"
}

# Stop all services (전체 중지 - 초기 배포나 완전 재시작 시에만 사용)
stop_all_services() {
    log "Stopping ALL services..."
    
    cd "$DEPLOY_DIR"
    
    if docker compose ps | grep -q "Up"; then
        info "Stopping all containers gracefully..."
        docker compose down --timeout 30 || warn "Some services may not have stopped gracefully"
        log "All services stopped ✓"
    else
        log "No running services found"
    fi
}

# Airflow 배포 함수
deploy_airflow() {
    log "========================================="
    log "Deploying Airflow Services"
    log "Airflow Version: ${AIRFLOW_VERSION:-latest}"
    log "========================================="
    
    # Airflow 디렉토리로 이동
    if [ ! -d "$AIRFLOW_DIR" ]; then
        warn "Airflow directory not found: $AIRFLOW_DIR - Skipping Airflow deployment"
        return 0
    fi
    
    cd "$AIRFLOW_DIR" || error "Failed to change directory to $AIRFLOW_DIR"
    
    # Step 1: Airflow docker-compose 파일 확인
    if [ ! -f "$AIRFLOW_COMPOSE_FILE" ]; then
        warn "Airflow docker-compose file not found: $AIRFLOW_COMPOSE_FILE - Skipping Airflow deployment"
        return 0
    fi
    
    # Step 2: Airflow 이미지 Pull
    info "Pulling Airflow Docker images..."
    # AIRFLOW_VERSION 환경변수를 docker-compose에 전달
    if ! AIRFLOW_VERSION="${AIRFLOW_VERSION:-latest}" docker compose -f "$AIRFLOW_COMPOSE_FILE" pull 2>&1 | tee -a "$LOG_FILE"; then
        warn "Failed to pull some Airflow images, continuing with existing images"
    fi
    log "Airflow images pulled ✓"
    
    # Step 3: Airflow 서비스 재시작
    info "Restarting Airflow services..."
    
    # 기존 Airflow 컨테이너 중지
    if docker compose -f "$AIRFLOW_COMPOSE_FILE" stop 2>&1 | tee -a "$LOG_FILE"; then
        log "Airflow services stopped ✓"
    else
        warn "Some Airflow services may not have been running"
    fi
    
    # 중지된 컨테이너 제거
    if docker compose -f "$AIRFLOW_COMPOSE_FILE" rm -f 2>&1 | tee -a "$LOG_FILE"; then
        log "Old Airflow containers removed ✓"
    fi
    
    # 새 Airflow 컨테이너 시작
    if ! AIRFLOW_VERSION="${AIRFLOW_VERSION:-latest}" docker compose -f "$AIRFLOW_COMPOSE_FILE" up -d --force-recreate 2>&1 | tee -a "$LOG_FILE"; then
        error "Failed to start Airflow services"
    fi
    
    log "Airflow services started successfully ✓"
    
    # Step 4: Airflow 초기화 대기
    info "Waiting for Airflow to initialize..."
    sleep 20
    
    log "========================================="
    log "Airflow Deployment Completed"
    log "========================================="
}

# Restart application services only (DB, nginx는 유지)
restart_app_services() {
    log "========================================="
    log "Restarting Application Services"
    log "Backend Version: ${BACKEND_VERSION:-latest}"
    log "AI Service Version: ${AI_VERSION:-latest}"
    log "Airflow Version: ${AIRFLOW_VERSION:-latest}"
    log "========================================="
    
    cd "$DEPLOY_DIR" || error "Failed to change directory to $DEPLOY_DIR"
    
    # Step 1: Docker 데몬 상태 확인 (CRITICAL)
    info "Verifying Docker daemon status..."
    if ! docker info > /dev/null 2>&1; then
        error "Cannot connect to Docker daemon. Please check:\n  1. Docker service is running\n  2. Current user has Docker permissions"
    fi
    log "Docker daemon is accessible ✓"
    
    # Step 2: 기존 컨테이너 중지
    info "Stopping application services..."
    if docker compose stop $APP_SERVICES 2>&1 | tee -a "$LOG_FILE"; then
        log "Services stopped successfully ✓"
    else
        warn "Failed to stop some services (they may not be running)"
    fi
    
    # Step 3: 중지된 컨테이너 제거
    info "Removing old containers..."
    if docker compose rm -f $APP_SERVICES 2>&1 | tee -a "$LOG_FILE"; then
        log "Old containers removed ✓"
    else
        warn "Failed to remove some containers (they may already be removed)"
    fi
    
    # Step 4: 좀비 컨테이너 정리 (에러 무시)
    info "Cleaning up orphaned containers..."
    local found_orphans=false
    for service in $APP_SERVICES; do
        local container_name="dollar-insight-${service}"
        if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$" 2>/dev/null; then
            found_orphans=true
            warn "Found orphaned container: ${container_name}"
            docker rm -f "${container_name}" 2>&1 | tee -a "$LOG_FILE" || true
        fi
    done
    
    if [ "$found_orphans" = false ]; then
        log "No orphaned containers found ✓"
    else
        log "Orphaned containers cleaned up ✓"
    fi
    
    # Step 5: 새 컨테이너 생성 및 시작 (CRITICAL - 실패하면 중단)
    info "Starting new containers..."
    if ! docker compose up -d --no-deps $APP_SERVICES 2>&1 | tee -a "$LOG_FILE"; then
        error "CRITICAL: Failed to start application services\n  Check logs at: $LOG_FILE\n  Or run: docker compose logs $APP_SERVICES"
    fi
    log "New containers started successfully ✓"
    
    # Step 6: 동적 DNS 해석을 사용하므로 Nginx 재시작 불필요
    info "Note: Nginx DNS cache will auto-refresh (dynamic DNS enabled)"
    log "No nginx restart required ✓"
    
    # Step 7: 컨테이너 안정화 대기
    info "Waiting for services to stabilize..."
    sleep 10
    
    # Step 8: Airflow 배포
    deploy_airflow

    # Step 9: Nginx 재시작 (동적 DNS 캐시 갱신)
    info "Restarting Nginx to refresh DNS cache..."
    if docker compose restart nginx 2>&1 | tee -a "$LOG_FILE"; then
        log "Nginx restarted successfully ✓"
    else
        warn "Failed to restart Nginx (service may not be running)"
    fi
    
    log "========================================="
    log "All Application Services Restarted Successfully"
    log "========================================="
}

# Start all services (초기 배포 시에만 사용)
start_all_services() {
    log "Starting ALL services..."
    
    cd "$DEPLOY_DIR"
    
    if ! docker compose up -d; then
        error "Failed to start services"
    fi
    
    log "All services started ✓"
    
    # Wait for containers to initialize
    sleep 15
}

# Health check
health_check() {
    log "Performing health checks..."
    
    local max_attempts=30
    local attempt=0
    local all_healthy=false
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        info "Health check attempt $attempt/$max_attempts..."
        
        local backend_healthy=false
        local ai_healthy=false
        local nginx_healthy=false
        local airflow_healthy=false
        
        # Check Backend (포트 9090)
        if curl -f -s http://localhost:9090/actuator/health > /dev/null 2>&1; then
            log "Backend is healthy ✓"
            backend_healthy=true
        else
            warn "Backend is not ready yet..."
        fi
        
        # Check AI service (포트 8000)
        if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
            log "AI service is healthy ✓"
            ai_healthy=true
        else
            warn "AI service is not ready yet..."
        fi
        
        # Check Nginx (포트 80)
        if curl -f -s http://localhost:80/health > /dev/null 2>&1; then
            log "Nginx is healthy ✓"
            nginx_healthy=true
        else
            warn "Nginx is not ready yet..."
        fi
        
        # Check Airflow (포트 8090) - optional
        if curl -f -s http://localhost:8090/health > /dev/null 2>&1 || curl -f -s http://localhost:8090 > /dev/null 2>&1; then
            log "Airflow is healthy ✓"
            airflow_healthy=true
        else
            warn "Airflow is not ready yet (optional service)..."
        fi
        
        # Check if all critical services are healthy (Airflow는 optional)
        if [ "$backend_healthy" = true ] && [ "$ai_healthy" = true ]; then
            all_healthy=true
            
            if [ "$nginx_healthy" = false ]; then
                warn "Nginx is not healthy but core services are running"
            fi
            
            if [ "$airflow_healthy" = false ]; then
                warn "Airflow is not healthy (optional service)"
            fi
            
            break
        fi
        
        sleep 10
    done
    
    if [ "$all_healthy" = false ]; then
        error "Health check failed after $max_attempts attempts. Please check logs: docker compose logs"
    fi
    
    log "All critical services are healthy ✓"
}

# Show detailed service status
show_status() {
    log "Current service status:"
    echo ""
    
    # Main services status
    cd "$DEPLOY_DIR"
    
    info "Main services:"
    if ! docker compose ps 2>/dev/null; then
        warn "No main services running or docker-compose.yml not found"
    fi
    
    echo ""
    
    # Airflow services status
    if [ -d "$AIRFLOW_DIR" ] && [ -f "$AIRFLOW_DIR/$AIRFLOW_COMPOSE_FILE" ]; then
        info "Airflow services:"
        cd "$AIRFLOW_DIR"
        docker compose -f "$AIRFLOW_COMPOSE_FILE" ps 2>/dev/null || warn "Airflow services not running"
        cd "$DEPLOY_DIR"
    fi
    
    echo ""
    log "Container resource usage:"
    
    # 모든 실행 중인 컨테이너 통계
    local all_running_containers=$(docker ps -q 2>/dev/null)
    
    if [ -n "$all_running_containers" ]; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
            $all_running_containers
    else
        warn "No running containers found"
    fi
}

# View logs
view_logs() {
    local service=${1:-}
    
    if [ -z "$service" ]; then
        # Show all services logs
        cd "$DEPLOY_DIR"
        info "Showing logs for all main services..."
        docker compose logs -f --tail=100
    elif [ "$service" = "airflow" ] || [[ "$service" == airflow-* ]]; then
        # Show Airflow logs
        if [ -d "$AIRFLOW_DIR" ] && [ -f "$AIRFLOW_DIR/$AIRFLOW_COMPOSE_FILE" ]; then
            cd "$AIRFLOW_DIR"
            if [ "$service" = "airflow" ]; then
                info "Showing logs for all Airflow services..."
                docker compose -f "$AIRFLOW_COMPOSE_FILE" logs -f --tail=100
            else
                info "Showing logs for $service..."
                docker compose -f "$AIRFLOW_COMPOSE_FILE" logs -f --tail=100 "$service"
            fi
        else
            error "Airflow is not deployed or configuration not found"
        fi
    else
        # Show specific service logs
        cd "$DEPLOY_DIR"
        info "Showing logs for $service..."
        docker compose logs -f --tail=100 "$service"
    fi
}

# Rollback to previous version
rollback() {
    log "Rolling back to previous version..."
    
    local latest_backup=$(ls -1dt "$BACKUP_DIR"/backup_* 2>/dev/null | head -n 1)
    
    if [ -z "$latest_backup" ]; then
        error "No backup found for rollback"
    fi
    
    log "Using backup: $latest_backup"
    
    # Stop current application services
    cd "$DEPLOY_DIR"
    docker compose stop $APP_SERVICES || true
    
    # Stop Airflow services if exists
    if [ -d "$AIRFLOW_DIR" ] && [ -f "$AIRFLOW_DIR/$AIRFLOW_COMPOSE_FILE" ]; then
        cd "$AIRFLOW_DIR"
        docker compose -f "$AIRFLOW_COMPOSE_FILE" stop || true
    fi
    
    # Restore backup files
    cd "$DEPLOY_DIR"
    if [ -f "$latest_backup/$COMPOSE_FILE" ]; then
        cp "$latest_backup/$COMPOSE_FILE" "$DEPLOY_DIR/"
    fi
    
    if [ -f "$latest_backup/backend.env" ]; then
        cp "$latest_backup/backend.env" "$DEPLOY_DIR/backend/.env"
    fi
    
    if [ -f "$latest_backup/ai-service.env" ]; then
        cp "$latest_backup/ai-service.env" "$DEPLOY_DIR/ai-service/.env"
    fi
    
    # Restore Airflow configuration if exists in backup
    if [ -d "$latest_backup/airflow" ] && [ -d "$AIRFLOW_DIR" ]; then
        if [ -f "$latest_backup/airflow/$AIRFLOW_COMPOSE_FILE" ]; then
            cp "$latest_backup/airflow/$AIRFLOW_COMPOSE_FILE" "$AIRFLOW_DIR/"
        fi
        if [ -f "$latest_backup/airflow/.env" ]; then
            cp "$latest_backup/airflow/.env" "$AIRFLOW_DIR/"
        fi
        log "Airflow configuration restored ✓"
    fi
    
    # Restart application services
    cd "$DEPLOY_DIR"
    docker compose up -d --force-recreate --no-deps $APP_SERVICES
    
    # Restart Airflow services if configuration was restored
    if [ -d "$AIRFLOW_DIR" ] && [ -f "$AIRFLOW_DIR/$AIRFLOW_COMPOSE_FILE" ]; then
        cd "$AIRFLOW_DIR"
        docker compose -f "$AIRFLOW_COMPOSE_FILE" up -d --force-recreate
        log "Airflow services restarted ✓"
    fi
    
    log "Rollback completed ✓"
    
    # Health check after rollback
    health_check
}

# ============================================
# Flutter APK Build & Deploy Functions  
# ============================================

# Build Flutter APK
build_apk() {
    log "========================================="
    log "Building Flutter APK"
    log "========================================="
    
    local FRONTEND_DIR="${DEPLOY_DIR}/frontend"
    local APK_OUTPUT_DIR="${FRONTEND_DIR}/build/app/outputs/flutter-apk"
    
    # Step 1: Check if frontend directory exists
    if [ ! -d "$FRONTEND_DIR" ]; then
        error "Frontend directory not found: $FRONTEND_DIR"
    fi
    
    # Step 2: Navigate to frontend directory
    cd "$FRONTEND_DIR" || error "Failed to change directory to $FRONTEND_DIR"
    log "Working directory: $(pwd)"
    
    # Step 3: Check Flutter environment
    info "Checking Flutter environment..."
    if ! command -v flutter &> /dev/null; then
        error "Flutter command not found. Please ensure Flutter is installed and in PATH."
    fi
    
    flutter --version || error "Flutter version check failed"
    log "Flutter environment verified ✓"
    
    # Step 4: Clean previous build
    info "Cleaning previous build..."
    flutter clean || warn "Flutter clean failed (continuing anyway)"
    
    # Step 5: Get dependencies
    info "Getting Flutter dependencies..."
    flutter pub get || error "Failed to get Flutter dependencies"
    log "Dependencies fetched ✓"
    
    # Step 6: Build APK
    info "Building release APK (this may take several minutes)..."
    if ! flutter build apk --release; then
        error "Flutter APK build failed. Check logs above for details."
    fi
    
    # Step 7: Verify APK was created
    if [ ! -f "$APK_OUTPUT_DIR/app-release.apk" ]; then
        error "APK file not found after build: $APK_OUTPUT_DIR/app-release.apk"
    fi
    
    local APK_SIZE=$(du -h "$APK_OUTPUT_DIR/app-release.apk" | cut -f1)
    log "APK built successfully ✓"
    log "APK location: $APK_OUTPUT_DIR/app-release.apk"
    log "APK size: $APK_SIZE"
    
    log "========================================="
    log "Flutter APK Build Completed"
    log "========================================="
}

# Deploy APK to production location
deploy_apk() {
    log "========================================="
    log "Deploying Flutter APK"
    log "========================================="
    
    local FRONTEND_DIR="${DEPLOY_DIR}/frontend"
    local APK_SOURCE="${FRONTEND_DIR}/build/app/outputs/flutter-apk/app-release.apk"
    local APK_DEPLOY_DIR="${DEPLOY_DIR}/apk"
    local APK_DEST="${APK_DEPLOY_DIR}/app-release.apk"
    
    # Step 1: Verify source APK exists
    if [ ! -f "$APK_SOURCE" ]; then
        error "Source APK not found: $APK_SOURCE\nPlease run build-apk first."
    fi
    
    # Step 2: Create deployment directory if it doesn't exist
    info "Preparing deployment directory..."
    sudo mkdir -p "$APK_DEPLOY_DIR" || error "Failed to create APK deployment directory"
    
    # Step 3: Backup existing APK if it exists
    if [ -f "$APK_DEST" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_path="${APK_DEPLOY_DIR}/app-release.apk.backup_${timestamp}"
        info "Backing up existing APK..."
        sudo cp "$APK_DEST" "$backup_path" || warn "Failed to backup existing APK"
        log "Backup created: $backup_path"
    fi
    
    # Step 4: Copy new APK to deployment location (using sudo)
    info "Copying APK to deployment location..."
    sudo cp "$APK_SOURCE" "$APK_DEST" || error "Failed to copy APK to deployment location"
    
    # Step 5: Set appropriate permissions
    sudo chmod 644 "$APK_DEST" || warn "Failed to set APK permissions"
    
    # Step 6: Verify deployment
    if [ ! -f "$APK_DEST" ]; then
        error "APK deployment verification failed"
    fi
    
    local APK_SIZE=$(du -h "$APK_DEST" | cut -f1)
    log "APK deployed successfully ✓"
    log "Deployment location: $APK_DEST"
    log "APK size: $APK_SIZE"
    log "Download URL: https://k13b205.p.ssafy.io/apk/app-release.apk"
    
    log "========================================="
    log "Flutter APK Deployment Completed"
    log "========================================="
}

# Build and deploy APK (combined operation)
build_and_deploy_apk() {
    log "========================================="
    log "Flutter APK - Build & Deploy"
    log "========================================="
    
    build_apk
    deploy_apk
    
    log "========================================="
    log "Flutter APK Build & Deploy Completed! 🎉"
    log "========================================="
    echo ""
    log "APK Download URLs:"
    log "  - HTTPS: https://k13b205.p.ssafy.io/apk/app-release.apk"
    log "  - HTTP: http://k13b205.p.ssafy.io/apk/app-release.apk"
    log ""
    log "Download Page:"
    log "  - https://k13b205.p.ssafy.io/download"
}

# Cleanup old Docker resources
cleanup_docker() {
    log "Cleaning up unused Docker resources..."
    
    # Remove dangling images
    info "Removing dangling images..."
    docker image prune -f || warn "Failed to prune images"
    
    # Remove unused networks
    info "Removing unused networks..."
    docker network prune -f || warn "Failed to prune networks"
    
    log "Docker cleanup completed ✓"
}

# Restart specific service
restart_service() {
    local service=$1
    
    if [ -z "$service" ]; then
        error "Service name is required. Usage: $0 restart-service <service-name>"
    fi
    
    log "Restarting service: $service"
    
    # Check if it's an Airflow service
    if [ "$service" = "airflow" ] || [[ "$service" == airflow-* ]]; then
        if [ -d "$AIRFLOW_DIR" ] && [ -f "$AIRFLOW_DIR/$AIRFLOW_COMPOSE_FILE" ]; then
            cd "$AIRFLOW_DIR"
            if [ "$service" = "airflow" ]; then
                docker compose -f "$AIRFLOW_COMPOSE_FILE" restart
                log "All Airflow services restarted ✓"
            else
                docker compose -f "$AIRFLOW_COMPOSE_FILE" restart "$service"
                log "Service $service restarted ✓"
            fi
        else
            error "Airflow is not deployed or configuration not found"
        fi
    else
        cd "$DEPLOY_DIR"
        docker compose restart "$service"
        log "Service $service restarted ✓"
    fi
}

# Main deployment function (애플리케이션 서비스 + Airflow 업데이트)
deploy() {
    log "========================================="
    log "Starting Dollar In\$ight Deployment"
    log "Updating Application Services + Airflow"
    log "DB, Nginx, Admin Tools Keep Running"
    log "========================================="
    
    check_permissions
    create_directories
    backup_current_deployment
    pull_images
    restart_app_services
    health_check
    show_status
    
    log "========================================="
    log "Deployment completed successfully! 🎉"
    log "========================================="
    echo ""
    log "Updated Services: $APP_SERVICES + Airflow"
    log "Preserved Services: postgres, mongodb, redis, chromadb, nginx, pgadmin, mongo-express, redis-commander"
    echo ""
    log "Service URLs:"
    log "  - Backend API: http://localhost:9090"
    log "  - AI Service: http://localhost:8000"
    log "  - Airflow UI: http://localhost:8090 (airflow/airflow)"
    log "  - Nginx Gateway: http://localhost:80"
    log "  - Backend Health: http://localhost:9090/actuator/health"
    log "  - AI Health: http://localhost:8000/health"
}

# Initial deployment (모든 서비스 시작)
deploy_initial() {
    log "========================================="
    log "Initial Dollar In\$ight Deployment"
    log "Starting All Services"
    log "========================================="
    
    check_permissions
    create_directories
    backup_current_deployment
    
    cd "$DEPLOY_DIR"
    
    # Pull all images
    log "Pulling all Docker images..."
    docker compose pull
    
    # Start all services
    start_all_services
    health_check
    show_status
    
    log "========================================="
    log "Initial deployment completed! 🎉"
    log "========================================="
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    deploy-all)
        deploy_initial
        ;;
    rollback)
        rollback
        ;;
    status)
        show_status
        ;;
    stop)
        stop_all_services
        ;;
    start)
        start_all_services
        health_check
        ;;
    restart)
        restart_app_services
        health_check
        ;;
    restart-all)
        stop_all_services
        start_all_services
        health_check
        ;;
    restart-service)
        restart_service "$2"
        ;;
    logs)
        view_logs "$2"
        ;;
    health)
        health_check
        ;;
    cleanup)
        cleanup_docker
        ;;
    build-apk)
        build_apk
        ;;
    deploy-apk)
        deploy_apk
        ;;
    build-and-deploy-apk)
        build_and_deploy_apk
        ;;
    *)
    
        echo "Dollar In\$ight Deployment Script (Optimized)"
        echo ""
        echo "Usage: $0 {command} [options]"
        echo ""
        echo "Commands:"
        echo "  deploy              - Update application services + Airflow"
        echo "                        (backend, ai-service, airflow)"
        echo "                        DB, nginx, admin tools keep running [RECOMMENDED]"
        echo "  build-apk           - Build Flutter APK only"
        echo "  deploy-apk          - Deploy pre-built APK to production"
        echo "  build-and-deploy-apk - Build and deploy Flutter APK (combined)"
        echo "  deploy-all          - Initial deployment (start all services)"
        echo "  rollback            - Rollback application services to previous version"
        echo "  status              - Show service status and resource usage"
        echo "  stop                - Stop all services"
        echo "  start               - Start all services"
        echo "  restart             - Restart application services + Airflow"
        echo "  restart-all         - Restart all services"
        echo "  restart-service <n> - Restart specific service"
        echo "  logs [service]      - View logs (all services or specific service)"
        echo "  health              - Run health checks"
        echo "  cleanup             - Clean up unused Docker resources"
        echo ""
        echo "Examples:"
        echo "  ./deploy.sh deploy                    # Update app services + Airflow (recommended)"
        echo "  ./deploy.sh build-and-deploy-apk      # Build and deploy Flutter APK"
        echo "  ./deploy.sh build-apk                 # Build APK only"
        echo "  ./deploy.sh deploy-apk                # Deploy pre-built APK"
        echo "  ./deploy.sh deploy-all                # Initial deployment"
        echo "  ./deploy.sh restart                   # Quick restart of app services + Airflow"
        echo "  ./deploy.sh restart-all               # Full system restart"
        echo "  ./deploy.sh logs backend              # View backend logs"
        echo "  ./deploy.sh logs airflow              # View all Airflow logs"
        echo "  ./deploy.sh logs airflow-webserver    # View specific Airflow service logs"
        echo "  ./deploy.sh restart-service postgres  # Restart specific service"
        echo "  ./deploy.sh restart-service airflow   # Restart all Airflow services"
        echo ""
        echo "Service Groups:"
        echo "  Application: backend, ai-service, airflow (updated by 'deploy')"
        echo "  Infrastructure: nginx (preserved)"
        echo "  Databases: postgres, mongodb, redis, chromadb (preserved)"
        echo "  Admin Tools: pgadmin, mongo-express, redis-commander (preserved)"
        echo ""
        echo "Prerequisites:"
        echo "  1. Docker installed and running"
        echo "  2. Current user in 'docker' group: sudo usermod -aG docker \$USER"
        echo "  3. Environment files exist:"
        echo "     - /opt/S13P31B205/backend/.env"
        echo "     - /opt/S13P31B205/ai-service/.env"
        echo "  4. docker-compose.yml exists in /opt/S13P31B205"
        exit 1
        ;;
esac
