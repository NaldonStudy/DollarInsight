pipeline {
    agent any
    
    environment {
        // Git 정보
        GIT_CREDENTIAL = 'gitlab-credential'
        
        // 배포 서버 정보 (1대)
        DEPLOY_SERVER = 'ubuntu@k13b205.p.ssafy.io'
        DEPLOY_PATH = '/opt/S13P31B205'
        SSH_CREDENTIAL = 'ec2-ssh-key'
        
        PROJECT_NAME = 'dollar-insight'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '=== Git Repository Checkout ==='
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an: %s"'
            }
        }
        
        stage('Backend - Test') {
            steps {
                echo '=== Backend Unit Test ==='
                dir('backend') {
                    sh '''
                        chmod +x gradlew
                        ./gradlew clean test --no-daemon
                    '''
                }
            }
            post {
                always {
                    junit 'backend/build/test-results/test/*.xml'
                }
            }
        }
        
        stage('Backend - Build') {
            steps {
                echo '=== Backend Build (Gradle) ==='
                dir('backend') {
                    sh '''
                        ./gradlew clean build -x test --no-daemon
                        ls -lh build/libs/
                    '''
                }
            }
        }
        
        stage('AI Service - Test') {
            steps {
                echo '=== AI Service Syntax Check ==='
                dir('ai-service') {
                    sh '''
                        python3 -m py_compile main.py
                    '''
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo '=== Deploy to Production Server ==='
                sshagent([SSH_CREDENTIAL]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            cd ${DEPLOY_PATH}
                            
                            # Git Pull
                            echo "=== Pulling latest master branch ==="
                            git checkout master
                            git pull origin master
                            
                            # 환경 변수 파일 확인
                            if [ ! -f .env ]; then
                                echo "ERROR: .env file not found!"
                                exit 1
                            fi
                            
                            # 기존 컨테이너 중지
                            echo "=== Stopping old containers ==="
                            docker compose down
                            
                            # Docker 이미지 빌드 (서버에서 직접 빌드)
                            echo "=== Building Docker Images on Server ==="
                            docker build -t ${PROJECT_NAME}-backend:latest backend/
                            docker build -t ${PROJECT_NAME}-ai-service:latest ai-service/
                            docker build -t ${PROJECT_NAME}-nginx:latest nginx/
                            
                            # 컨테이너 실행
                            echo "=== Starting containers ==="
                            docker compose up -d
                            
                            # 컨테이너 상태 확인
                            docker compose ps
                        '
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '=== Health Check ==='
                script {
                    sleep(time: 30, unit: 'SECONDS')
                    
                    sshagent([SSH_CREDENTIAL]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                                # Backend Health Check
                                echo "=== Backend Health Check ==="
                                for i in {1..30}; do
                                    if curl -f http://localhost:9090/actuator/health > /dev/null 2>&1; then
                                        echo "✓ Backend is healthy"
                                        break
                                    fi
                                    echo "Waiting for backend... (\$i/30)"
                                    sleep 2
                                done
                                
                                # AI Service Health Check
                                echo "=== AI Service Health Check ==="
                                for i in {1..30}; do
                                    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
                                        echo "✓ AI Service is healthy"
                                        break
                                    fi
                                    echo "Waiting for AI service... (\$i/30)"
                                    sleep 2
                                done
                                
                                # Nginx Health Check
                                echo "=== Nginx Health Check ==="
                                if curl -f http://localhost:80/health > /dev/null 2>&1; then
                                    echo "✓ Nginx is healthy"
                                else
                                    echo "⚠ Nginx health check failed (non-critical)"
                                fi
                                
                                echo "=== Deployment Complete ==="
                                docker compose ps
                            '
                        """
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                echo '=== Cleanup Old Images ==='
                sshagent([SSH_CREDENTIAL]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            # 사용하지 않는 이미지 정리
                            docker image prune -af --filter "until=24h"
                            echo "Cleanup completed"
                        '
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '=== ✅ Deployment Success ==='
            echo "Build Number: ${BUILD_NUMBER}"
            
            // Slack 알림 (선택)
            // slackSend(
            //     color: 'good',
            //     message: "✅ Deployment Success\nBuild: #${env.BUILD_NUMBER}"
            // )
        }
        
        failure {
            echo '=== ❌ Deployment Failed ==='
            
            // Slack 알림 (선택)
            // slackSend(
            //     color: 'danger',
            //     message: "❌ Deployment Failed\nBuild: #${env.BUILD_NUMBER}"
            // )
        }
        
        always {
            echo '=== Cleaning up workspace ==='
            cleanWs()
        }
    }
}