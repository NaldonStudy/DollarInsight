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
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="/opt/dollar-insight"
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
        cp -r "$DEPLOY_DIR"/* "$backup_path/" 2>/dev/null || true
        
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
    docker-compose pull || error "Failed to pull Docker images"
    
    log "Docker images pulled ✓"
}

# Stop running services
stop_services() {
    log "Stopping running services..."
    
    cd "$DEPLOY_DIR"
    
    if docker-compose ps | grep -q "Up"; then
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
    docker-compose up -d || error "Failed to start services"
    
    log "Services started ✓"
}

# Health check
health_check() {
    log "Performing health checks..."
    
    local max_attempts=30
    local attempt=0
    local all_healthy=false
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        log "Health check attempt $attempt/$max_attempts..."
        
        # Check backend
        if curl -f -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
            log "Backend is healthy ✓"
            backend_healthy=true
        else
            backend_healthy=false
        fi
        
        # Check AI service
        if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
            log "AI service is healthy ✓"
            ai_healthy=true
        else
            ai_healthy=false
        fi
        
        # Check if all services are healthy
        if [ "$backend_healthy" = true ] && [ "$ai_healthy" = true ]; then
            all_healthy=true
            break
        fi
        
        sleep 10
    done
    
    if [ "$all_healthy" = false ]; then
        error "Health check failed after $max_attempts attempts"
    fi
    
    log "All services are healthy ✓"
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
    
    # Restore backup
    rm -rf "$DEPLOY_DIR"/*
    cp -r "$latest_backup"/* "$DEPLOY_DIR/"
    
    # Start services
    cd "$DEPLOY_DIR"
    docker-compose up -d
    
    log "Rollback completed ✓"
}

# Show service status
show_status() {
    log "Current service status:"
    cd "$DEPLOY_DIR"
    docker-compose ps
}

# Cleanup old Docker resources
cleanup_docker() {
    log "Cleaning up unused Docker resources..."
    
    # Remove dangling images
    docker image prune -f || warn "Failed to prune images"
    
    # Remove unused volumes (be careful!)
    # docker volume prune -f || warn "Failed to prune volumes"
    
    log "Docker cleanup completed ✓"
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
    cleanup_docker
    show_status
    
    log "========================================="
    log "Deployment completed successfully! 🎉"
    log "========================================="
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    status)
        show_status
        ;;
    stop)
        stop_services
        ;;
    start)
        start_services
        ;;
    restart)
        stop_services
        start_services
        health_check
        ;;
    logs)
        cd "$DEPLOY_DIR"
        docker-compose logs -f "${2:-}"
        ;;
    health)
        health_check
        ;;
    cleanup)
        cleanup_docker
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status|stop|start|restart|logs|health|cleanup}"
        exit 1
        ;;
esac
