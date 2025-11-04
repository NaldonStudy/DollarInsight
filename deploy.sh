#!/bin/bash

################################################################################
# Dollar In$ight - Deployment Script
# 
# This script handles the deployment of Dollar In$ight services
# Can be used both manually and by Jenkins CI/CD pipeline
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
BACKUP_DIR="/opt/dollar-insight-backups"
MAX_BACKUPS=5
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Logging
LOG_FILE="/var/log/dollar-insight-deploy.log"

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
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
    fi
}

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    local deps=("docker" "docker-compose")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "$dep is not installed. Please install it first."
        fi
    done
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running. Please start Docker first."
    fi
    
    log "All dependencies are installed ✓"
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
        
        # Backup docker-compose.yml and .env files
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

# Pull latest Docker images
pull_images() {
    log "Pulling latest Docker images..."
    
    cd "$DEPLOY_DIR"
    
    if ! docker-compose pull; then
        error "Failed to pull Docker images"
    fi
    
    log "Docker images pulled ✓"
}

# Stop running services
stop_services() {
    log "Stopping running services..."
    
    cd "$DEPLOY_DIR"
    
    if docker-compose ps | grep -q "Up"; then
        info "Stopping containers gracefully..."
        docker-compose down --timeout 30 || warn "Some services may not have stopped gracefully"
        log "Services stopped ✓"
    else
        log "No running services found"
    fi
}

# Start services
start_services() {
    log "Starting services..."
    
    cd "$DEPLOY_DIR"
    
    if ! docker-compose up -d; then
        error "Failed to start services"
    fi
    
    log "Services started ✓"
    
    # Wait for containers to initialize
    sleep 10
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
        error "Health check failed after $max_attempts attempts. Please check logs: docker-compose logs"
    fi
    
    log "All critical services are healthy ✓"
}

# Show detailed service status
show_status() {
    log "Current service status:"
    echo ""
    
    cd "$DEPLOY_DIR"
    docker-compose ps
    
    echo ""
    log "Container resource usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
        $(docker-compose ps -q)
}

# View logs
view_logs() {
    local service=${1:-}
    
    cd "$DEPLOY_DIR"
    
    if [ -z "$service" ]; then
        info "Showing logs for all services..."
        docker-compose logs -f --tail=100
    else
        info "Showing logs for $service..."
        docker-compose logs -f --tail=100 "$service"
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
    
    # Stop current services
    cd "$DEPLOY_DIR"
    docker-compose down --timeout 30 || true
    
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
    
    # Start services
    cd "$DEPLOY_DIR"
    docker-compose up -d
    
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
    
    # Optional: Remove unused volumes (주의: 데이터 손실 가능)
    # docker volume prune -f || warn "Failed to prune volumes"
    
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
    docker-compose restart "$service"
    
    log "Service $service restarted ✓"
}

# Main deployment function
deploy() {
    log "========================================="
    log "Starting Dollar In\$ight Deployment"
    log "========================================="
    
    check_permissions
    check_dependencies
    create_directories
    backup_current_deployment
    pull_images
    stop_services
    start_services
    health_check
    show_status
    
    log "========================================="
    log "Deployment completed successfully! 🎉"
    log "========================================="
    echo ""
    log "Service URLs:"
    log "  - Backend API: http://localhost:9090"
    log "  - AI Service: http://localhost:8000"
    log "  - Nginx Gateway: http://localhost:80"
    log "  - Backend Health: http://localhost:9090/actuator/health"
    log "  - AI Health: http://localhost:8000/health"
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    rollback)
        check_permissions
        rollback
        ;;
    status)
        show_status
        ;;
    stop)
        check_permissions
        stop_services
        ;;
    start)
        check_permissions
        start_services
        health_check
        ;;
    restart)
        check_permissions
        stop_services
        start_services
        health_check
        ;;
    restart-service)
        check_permissions
        restart_service "$2"
        ;;
    logs)
        view_logs "$2"
        ;;
    health)
        health_check
        ;;
    cleanup)
        check_permissions
        cleanup_docker
        ;;
    *)
        echo "Dollar In\$ight Deployment Script"
        echo ""
        echo "Usage: $0 {command} [options]"
        echo ""
        echo "Commands:"
        echo "  deploy              - Full deployment (pull, stop, start, health check)"
        echo "  rollback            - Rollback to previous version"
        echo "  status              - Show service status and resource usage"
        echo "  stop                - Stop all services"
        echo "  start               - Start all services"
        echo "  restart             - Restart all services"
        echo "  restart-service <name> - Restart specific service"
        echo "  logs [service]      - View logs (all services or specific service)"
        echo "  health              - Run health checks"
        echo "  cleanup             - Clean up unused Docker resources"
        echo ""
        echo "Examples:"
        echo "  sudo ./deploy.sh deploy"
        echo "  sudo ./deploy.sh rollback"
        echo "  sudo ./deploy.sh logs backend"
        echo "  sudo ./deploy.sh restart-service ai-service"
        exit 1
        ;;
esac
