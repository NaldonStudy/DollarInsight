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
    info "Target services: $APP_SERVICES"
    
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

# Restart application services only (DB, nginx는 유지)
restart_app_services() {
    log "Restarting application services (DB, nginx, admin tools keep running)..."
    info "Target services: $APP_SERVICES"
    
    cd "$DEPLOY_DIR"
    
    # Step 1: 기존 애플리케이션 컨테이너 중지
    info "Stopping application services..."
    docker compose stop $APP_SERVICES || warn "Some services may not be running"
    
    # Step 2: 기존 컨테이너 제거 (이미지는 유지)
    info "Removing old containers..."
    docker compose rm -f $APP_SERVICES || warn "Some containers may already be removed"
    
    # Step 3: 새 컨테이너 생성 및 시작
    info "Starting new containers..."
    if ! docker compose up -d --no-deps $APP_SERVICES; then
        error "Failed to start application services"
    fi
    
    log "Application services restarted ✓"
    
    # Wait for containers to initialize
    sleep 10
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
        
        # Check if all critical services are healthy
        if [ "$backend_healthy" = true ] && [ "$ai_healthy" = true ]; then
            all_healthy=true
            
            if [ "$nginx_healthy" = false ]; then
                warn "Nginx is not healthy but core services are running"
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
    
    cd "$DEPLOY_DIR"
    
    if ! docker compose ps 2>/dev/null; then
        warn "No services running or docker-compose.yml not found"
        return
    fi
    
    echo ""
    log "Container resource usage:"
    local running_containers=$(docker compose ps -q 2>/dev/null)
    
    if [ -n "$running_containers" ]; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
            $running_containers
    else
        warn "No running containers found"
    fi
}

# View logs
view_logs() {
    local service=${1:-}
    
    cd "$DEPLOY_DIR"
    
    if [ -z "$service" ]; then
        info "Showing logs for all services..."
        docker compose logs -f --tail=100
    else
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
    
    # Stop current application services only
    cd "$DEPLOY_DIR"
    docker compose stop $APP_SERVICES || true
    
    # Restore backup files
    if [ -f "$latest_backup/$COMPOSE_FILE" ]; then
        cp "$latest_backup/$COMPOSE_FILE" "$DEPLOY_DIR/"
    fi
    
    if [ -f "$latest_backup/backend.env" ]; then
        cp "$latest_backup/backend.env" "$DEPLOY_DIR/backend/.env"
    fi
    
    if [ -f "$latest_backup/ai-service.env" ]; then
        cp "$latest_backup/ai-service.env" "$DEPLOY_DIR/ai-service/.env"
    fi
    
    # Restart application services
    cd "$DEPLOY_DIR"
    docker compose up -d --force-recreate --no-deps $APP_SERVICES
    
    log "Rollback completed ✓"
    
    # Health check after rollback
    health_check
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
    
    cd "$DEPLOY_DIR"
    docker compose restart "$service"
    
    log "Service $service restarted ✓"
}

# Main deployment function (애플리케이션 서비스만 업데이트)
deploy() {
    log "========================================="
    log "Starting Dollar In\$ight Deployment"
    log "Updating Application Services Only"
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
    log "Updated Services: $APP_SERVICES"
    log "Preserved Services: postgres, mongodb, redis, chromadb, nginx, pgadmin, mongo-express, redis-commander"
    echo ""
    log "Service URLs:"
    log "  - Backend API: http://localhost:9090"
    log "  - AI Service: http://localhost:8000"
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
    *)
        echo "Dollar In\$ight Deployment Script (Optimized)"
        echo ""
        echo "Usage: $0 {command} [options]"
        echo ""
        echo "Commands:"
        echo "  deploy              - Update application services only (backend, ai-service)"
        echo "                        DB, nginx, admin tools keep running [RECOMMENDED]"
        echo "  deploy-all          - Initial deployment (start all services)"
        echo "  rollback            - Rollback application services to previous version"
        echo "  status              - Show service status and resource usage"
        echo "  stop                - Stop all services"
        echo "  start               - Start all services"
        echo "  restart             - Restart application services only"
        echo "  restart-all         - Restart all services"
        echo "  restart-service <n> - Restart specific service"
        echo "  logs [service]      - View logs (all services or specific service)"
        echo "  health              - Run health checks"
        echo "  cleanup             - Clean up unused Docker resources"
        echo ""
        echo "Examples:"
        echo "  ./deploy.sh deploy                    # Update app services only (recommended)"
        echo "  ./deploy.sh deploy-all                # Initial deployment"
        echo "  ./deploy.sh restart                   # Quick restart of app services"
        echo "  ./deploy.sh restart-all               # Full system restart"
        echo "  ./deploy.sh logs backend              # View backend logs"
        echo "  ./deploy.sh restart-service postgres  # Restart specific service"
        echo ""
        echo "Service Groups:"
        echo "  Application: backend, ai-service (updated by 'deploy')"
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
