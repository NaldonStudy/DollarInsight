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
        
        // ========================================
        // CI: Continuous Integration (테스트)
        // ========================================
        
        stage('Backend - Test') {
            steps {
                echo '=== Backend Test (JUnit) ==='
                dir('backend') {
                    sh '''
                        chmod +x gradlew
                        ./gradlew clean test --no-daemon
                    '''
                }
            }
            post {
                always {
                    // JUnit 테스트 결과 수집
                    junit '**/build/test-results/test/*.xml'
                    
                    // 테스트 리포트를 HTML로 발행
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'backend/build/reports/tests/test',
                        reportFiles: 'index.html',
                        reportName: 'Backend Test Report'
                    ])
                }
                success {
                    echo '✅ All backend tests passed!'
                }
                failure {
                    echo '❌ Backend tests failed! Stopping pipeline.'
                    error('Backend tests failed')
                }
            }
        }
        
        // ========================================
        // CD: Continuous Deployment (빌드 & 배포)
        // ========================================
        
        stage('Backend - Build') {
            steps {
                echo '=== Backend Build (Gradle) ==='
                dir('backend') {
                    sh '''
                        chmod +x gradlew
                        ./gradlew build -x test --no-daemon
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
                withCredentials([sshUserPrivateKey(credentialsId: SSH_CREDENTIAL, keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        # 필요한 파일들을 EC2로 전송
                        scp -i \${SSH_KEY} -o StrictHostKeyChecking=no docker-compose.yml ${DEPLOY_SERVER}:${DEPLOY_PATH}/
                        scp -i \${SSH_KEY} -o StrictHostKeyChecking=no deploy.sh ${DEPLOY_SERVER}:${DEPLOY_PATH}/
                        
                        ssh -i \${SSH_KEY} -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            cd ${DEPLOY_PATH}
                            
                            # deploy.sh 실행 권한 부여
                            chmod +x deploy.sh
                            
                            # deploy.sh를 사용한 배포 (Docker Hub 방식)
                            echo "=== Running deployment script ==="
                            ./deploy.sh deploy
                        '
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '=== Verifying Deployment ==='
                withCredentials([sshUserPrivateKey(credentialsId: SSH_CREDENTIAL, keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        ssh -i \${SSH_KEY} -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            cd ${DEPLOY_PATH}
                            
                            # deploy.sh의 status 명령으로 배포 상태 확인
                            echo "=== Checking deployment status ==="
                            ./deploy.sh status
                            
                            # Health check는 deploy.sh에서 이미 수행됨
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
                
                withCredentials([sshUserPrivateKey(credentialsId: SSH_CREDENTIAL, keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        ssh -i \${SSH_KEY} -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            cd ${DEPLOY_PATH}
                            
                            # deploy.sh의 cleanup 기능 사용
                            ./deploy.sh cleanup
                        '
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '=== ✅ CI/CD Pipeline Success ==='
            echo "Build Number: ${BUILD_NUMBER}"
            echo "Image Tag: ${IMAGE_TAG}"
            echo "All tests passed and deployment completed"
            echo "Deployed at: ${new Date()}"
            
            withCredentials([sshUserPrivateKey(credentialsId: SSH_CREDENTIAL, keyFileVariable: 'SSH_KEY')]) {
                sh """
                    ssh -i \${SSH_KEY} -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                        echo "=== 📊 Current Service Status ==="
                        cd ${DEPLOY_PATH}
                        docker compose ps
                    '
                """
            }
        }
        
        failure {
            echo '=== ❌ CI/CD Pipeline Failed ==='
            
            // 실패 시 로그 수집
            withCredentials([sshUserPrivateKey(credentialsId: SSH_CREDENTIAL, keyFileVariable: 'SSH_KEY')]) {
                sh """
                    ssh -i \${SSH_KEY} -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                        echo "=== 📋 Service Logs (Last 50 lines) ==="
                        cd ${DEPLOY_PATH}
                        ./deploy.sh logs || docker compose logs --tail=50
                    ' || true
                """
            }
        }
        
        unstable {
            echo '=== ⚠️ CI/CD Pipeline Unstable ==='
            echo 'Some tests may have failed or deployment is incomplete'
        }
        
        always {
            echo '=== Cleaning up workspace ==='
            cleanWs()
        }
    }
}
