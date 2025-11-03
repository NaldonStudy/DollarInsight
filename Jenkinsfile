pipeline {
    agent any
    
    environment {
        // Git 정보
        GIT_CREDENTIAL = 'gitlab-credential'
        
        // Docker Registry 정보 (GitLab Container Registry)
        REGISTRY = 'registry.lab.ssafy.com'
        REGISTRY_CREDENTIAL = 'gitlab-registry-credential'
        IMAGE_BASE = "${REGISTRY}/s13-final/s13p31b205"
        
        // 배포 서버 정보
        DEPLOY_SERVER = 'ubuntu@k13b205.p.ssafy.io'
        DEPLOY_PATH = '/opt/S13P31B205'
        SSH_CREDENTIAL = 'ec2-ssh-key'
        
        PROJECT_NAME = 'dollar-insight'
        
        // 이미지 태그 (Git Commit Hash + Build Number)
        IMAGE_TAG = "${GIT_COMMIT[0..7]}-${BUILD_NUMBER}"
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
        
        stage('Build Docker Images') {
            steps {
                echo '=== Building Docker Images in Jenkins ==='
                script {
                    // Backend 이미지 빌드
                    docker.build("${IMAGE_BASE}/backend:${IMAGE_TAG}", "./backend")
                    docker.build("${IMAGE_BASE}/backend:latest", "./backend")
                    
                    // AI Service 이미지 빌드
                    docker.build("${IMAGE_BASE}/ai-service:${IMAGE_TAG}", "./ai-service")
                    docker.build("${IMAGE_BASE}/ai-service:latest", "./ai-service")
                    
                    // Nginx 이미지 빌드
                    docker.build("${IMAGE_BASE}/nginx:${IMAGE_TAG}", "./nginx")
                    docker.build("${IMAGE_BASE}/nginx:latest", "./nginx")
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                echo '=== Pushing Images to GitLab Registry ==='
                script {
                    docker.withRegistry("https://${REGISTRY}", REGISTRY_CREDENTIAL) {
                        // Backend 푸시
                        docker.image("${IMAGE_BASE}/backend:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_BASE}/backend:latest").push()
                        
                        // AI Service 푸시
                        docker.image("${IMAGE_BASE}/ai-service:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_BASE}/ai-service:latest").push()
                        
                        // Nginx 푸시
                        docker.image("${IMAGE_BASE}/nginx:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_BASE}/nginx:latest").push()
                    }
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
                            
                            # Git Pull from develop branch
                            echo "=== Pulling latest develop branch ==="
                            git checkout develop
                            git pull origin develop
                            
                            # 환경 변수 파일 확인
                            if [ ! -f .env ]; then
                                echo "ERROR: .env file not found!"
                                exit 1
                            fi
                            
                            # Docker Registry 로그인
                            echo "=== Login to Docker Registry ==="
                            echo \${REGISTRY_PASSWORD} | docker login ${REGISTRY} -u \${REGISTRY_USER} --password-stdin
                            
                            # 기존 컨테이너 중지
                            echo "=== Stopping old containers ==="
                            docker compose down
                            
                            # 최신 이미지 Pull
                            echo "=== Pulling latest images from Registry ==="
                            docker pull ${IMAGE_BASE}/backend:latest
                            docker pull ${IMAGE_BASE}/ai-service:latest
                            docker pull ${IMAGE_BASE}/nginx:latest
                            
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
                script {
                    // Jenkins 서버의 오래된 이미지 정리
                    sh """
                        docker image prune -af --filter "until=24h"
                    """
                }
                
                sshagent([SSH_CREDENTIAL]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            # 배포 서버의 오래된 이미지 정리
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
            echo "Image Tag: ${IMAGE_TAG}"
            
            // Slack 알림 (선택)
            // slackSend(
            //     color: 'good',
            //     message: "✅ Deployment Success\nBuild: #${env.BUILD_NUMBER}\nTag: ${IMAGE_TAG}"
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
