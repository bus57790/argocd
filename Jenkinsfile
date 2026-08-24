pipeline {
    agent any

    environment {
        // Repository & Image Configuration
        GIT_REPO_URL     = 'github.com/YOUR_USERNAME/sample-microservice.git'
        DOCKER_REGISTRY  = 'docker.io'
        DOCKER_IMAGE     = 'YOUR_DOCKERHUB_USERNAME/sample-microservice'
        IMAGE_TAG        = "${BUILD_NUMBER}-${BUILD_TIMESTAMP}"
        
        // SonarQube Tool & Server Names (configured in Global Tool Configuration)
        SONAR_SERVER     = 'SonarQube-Server'
        SONAR_SCANNER    = 'SonarScanner'

        // Credentials IDs
        GIT_CREDS_ID     = 'github-access-token'
        DOCKER_CREDS_ID  = 'dockerhub-credentials'
        SLACK_WEBHOOK_ID = 'slack-webhook-url'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Initialize & Timestamp') {
            steps {
                script {
                    BUILD_TIMESTAMP = sh(script: "date +'%Y%m%d-%H%M%S'", returnStdout: true).trim()
                    echo "Building Release Tag: ${IMAGE_TAG}"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool SONAR_SCANNER
                    withSonarQubeEnv(SONAR_SERVER) {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=sample-microservice \
                              -Dsonar.projectName="Sample Microservice" \
                              -Dsonar.sources=. \
                              -Dsonar.exclusions="node_modules/**, coverage/**"
                        """
                    }
                }
            }
        }

        stage('Quality Gate Verification') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDS_ID) {
                        def customImage = docker.build("${DOCKER_IMAGE}:${IMAGE_TAG}")
                        customImage.push()
                        customImage.push("latest")
                    }
                }
            }
        }

        stage('Update K8s Manifests (GitOps Loop)') {
            steps {
                withCredentials([usernamePassword(credentialsId: GIT_CREDS_ID, passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    sh """
                        git config user.name "Jenkins CI"
                        git config user.email "ci@jenkins.local"
                        
                        # Update image tag inside deployment manifest using sed
                        sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${IMAGE_TAG}|g' k8s/deployment.yaml
                        
                        # Commit and push changes back to main branch for Argo CD sync
                        git add k8s/deployment.yaml
                        git commit -m "chore(ci): update deployment image tag to ${IMAGE_TAG} [skip ci]" || exit 0
                        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${GIT_REPO_URL} HEAD:main
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded! Argo CD will detect commit ${IMAGE_TAG} and auto-sync to Kubernetes."
            script {
                sendSlackNotification("SUCCESS", "Pipeline built successfully. Manifest updated to tag `${IMAGE_TAG}`. Waiting for Argo CD sync.")
            }
        }
        failure {
            echo "Pipeline failed! Deployment process halted."
            script {
                sendSlackNotification("FAILURE", "Pipeline failed at build `#${BUILD_NUMBER}`. Check Jenkins console logs for details.")
            }
        }
    }
}

// Helper Function for Pipeline Notifications
def sendSlackNotification(String status, String message) {
    withCredentials([string(credentialsId: SLACK_WEBHOOK_ID, variable: 'WEBHOOK_URL')]) {
        def color = (status == "SUCCESS") ? "#36a64f" : "#danger"
        def payload = """
        {
            "attachments": [
                {
                    "color": "${color}",
                    "title": "Jenkins CI: ${status}",
                    "text": "${message}",
                    "fields": [
                        { "title": "Job", "value": "${ENV:JOB_NAME}", "short": true },
                        { "title": "Build", "value": "#${ENV:BUILD_NUMBER}", "short": true }
                    ]
                }
            ]
        }
        """
        sh(script: "curl -X POST -H 'Content-Type: application/json' --data '${payload.replaceAll('\n', '')}' ${WEBHOOK_URL}", returnStdout: false)
    }
}
