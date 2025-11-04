pipeline {
    agent any
    
    environment {
        // Git 정보
        GIT_CREDENTIAL = 'gitlab-credential'
        
        // Docker Hub 정보
        DOCKERHUB_USERNAME = 'imtaewon'
        DOCKERHUB_CREDENTIAL = 'dockerhub-credential'
        IMAGE_BASE = "${DOCKERHUB_USERNAME}"
        
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
        
        stage('Backend - Build') {
            steps {
                echo '=== Backend Build (Gradle) ==='
                dir('backend') {
                    sh '''
                        chmod +x gradlew
                        ./gradlew clean build -x test --no-daemon
                        ls -lh build/libs/
                    '''
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                echo '=== Building Docker Images in Jenkins ==='
                script {
                    // Backend 이미지 빌드
                    docker.build("${IMAGE_BASE}/dollar-backend:${IMAGE_TAG}", "./backend")
                    docker.build("${IMAGE_BASE}/dollar-backend:latest", "./backend")
                    
                    // AI Service 이미지 빌드
                    docker.build("${IMAGE_BASE}/dollar-ai:${IMAGE_TAG}", "./ai-service")
                    docker.build("${IMAGE_BASE}/dollar-ai:latest", "./ai-service")
                    
                    // Nginx 이미지 빌드
                    docker.build("${IMAGE_BASE}/dollar-nginx:${IMAGE_TAG}", "./nginx")
                    docker.build("${IMAGE_BASE}/dollar-nginx:latest", "./nginx")
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                echo '=== Pushing Images to Docker Hub ==='
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIAL) {
                        // Backend 푸시
                        docker.image("${IMAGE_BASE}/dollar-backend:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_BASE}/dollar-backend:latest").push()
                        
                        // AI Service 푸시
                        docker.image("${IMAGE_BASE}/dollar-ai:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_BASE}/dollar-ai:latest").push()
                        
                        // Nginx 푸시
                        docker.image("${IMAGE_BASE}/dollar-nginx:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_BASE}/dollar-nginx:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo '=== Deploy to Production Server using deploy.sh ==='
                sshagent(credentials: [SSH_CREDENTIAL]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            cd ${DEPLOY_PATH}
                            
                            # Git Pull from develop branch
                            echo "=== Pulling latest develop branch ==="
                            git checkout develop
                            git pull origin develop
                            
                            # 환경 변수 파일 확인
                            if [ ! -f backend/.env ] || [ ! -f ai-service/.env ]; then
                                echo "ERROR: .env files not found!"
                                echo "Please create .env files in backend/ and ai-service/ directories"
                                exit 1
                            fi
                            
                            # deploy.sh 실행 권한 부여
                            chmod +x deploy.sh
                            
                            # deploy.sh를 사용한 배포
                            echo "=== Running deployment script ==="
                            sudo ./deploy.sh deploy
                        '
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '=== Verifying Deployment ==='
                sshagent(credentials: [SSH_CREDENTIAL]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            cd ${DEPLOY_PATH}
                            
                            # 배포 상태 확인
                            echo "=== Checking deployment status ==="
                            sudo ./deploy.sh status
                            
                            # 서비스별 상태 확인
                            echo ""
                            echo "=== Service Health Check Results ==="
                            
                            # Backend
                            if curl -f http://localhost:9090/actuator/health > /dev/null 2>&1; then
                                echo "✅ Backend: HEALTHY"
                            else
                                echo "❌ Backend: UNHEALTHY"
                                exit 1
                            fi
                            
                            # AI Service
                            if curl -f http://localhost:8000/health > /dev/null 2>&1; then
                                echo "✅ AI Service: HEALTHY"
                            else
                                echo "❌ AI Service: UNHEALTHY"
                                exit 1
                            fi
                            
                            # Nginx
                            if curl -f http://localhost:80/health > /dev/null 2>&1; then
                                echo "✅ Nginx: HEALTHY"
                            else
                                echo "⚠️  Nginx: UNHEALTHY (non-critical)"
                            fi
                            
                            echo ""
                            echo "=== Deployment Verification Complete ==="
                        '
                    """
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
                
                sshagent(credentials: [SSH_CREDENTIAL]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            cd ${DEPLOY_PATH}
                            
                            # deploy.sh의 cleanup 기능 사용
                            sudo ./deploy.sh cleanup
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
            echo "Deployed at: ${new Date()}"
            
            sshagent(credentials: [SSH_CREDENTIAL]) {
                sh """
                    ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                        echo "=== 📊 Current Service Status ==="
                        cd ${DEPLOY_PATH}
                        sudo docker-compose ps
                    '
                """
            }
            
            // Slack 알림 (Slack 플러그인 설치 및 설정 후 활성화)
            // slackSend(
            //     channel: '#deployments',
            //     color: 'good',
            //     message: """
            //         ✅ *Deployment Success*
            //         Project: ${PROJECT_NAME}
            //         Build: #${env.BUILD_NUMBER}
            //         Tag: ${IMAGE_TAG}
            //         Branch: ${env.GIT_BRANCH}
            //         Deployed by: ${env.BUILD_USER}
            //     """
            // )
        }
        
        failure {
            echo '=== ❌ Deployment Failed ==='
            
            // 실패 시 로그 수집
            sshagent(credentials: [SSH_CREDENTIAL]) {
                sh """
                    ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                        echo "=== 📋 Service Logs (Last 50 lines) ==="
                        cd ${DEPLOY_PATH}
                        sudo docker-compose logs --tail=50
                    ' || true
                """
            }
            
            // Slack 알림 (Slack 플러그인 설치 및 설정 후 활성화)
            // slackSend(
            //     channel: '#deployments',
            //     color: 'danger',
            //     message: """
            //         ❌ *Deployment Failed*
            //         Project: ${PROJECT_NAME}
            //         Build: #${env.BUILD_NUMBER}
            //         Branch: ${env.GIT_BRANCH}
            //         Check Jenkins: ${env.BUILD_URL}
            //     """
            // )
        }
        
        unstable {
            echo '=== ⚠️ Deployment Unstable ==='
            
            // Slack 알림
            // slackSend(
            //     channel: '#deployments',
            //     color: 'warning',
            //     message: """
            //         ⚠️ *Deployment Unstable*
            //         Project: ${PROJECT_NAME}
            //         Build: #${env.BUILD_NUMBER}
            //         Some tests may have failed
            //     """
            // )
        }
        
        always {
            echo '=== Cleaning up workspace ==='
            cleanWs()
        }
    }
}
