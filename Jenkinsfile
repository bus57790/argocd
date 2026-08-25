pipeline {
    agent any

    environment {
        // Repository & Image Configuration for local lab
        GIT_REPO_URL     = 'github.com/bus57790/argocd.git'
        DOCKER_REGISTRY  = 'docker.io'
        DOCKER_IMAGE     = 'bus57790/sample-microservice'
        
        // SonarQube Tool & Server Names
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
                    def timestamp = sh(script: "date +'%Y%m%d-%H%M%S'", returnStdout: true).trim()
                    env.IMAGE_TAG = "${BUILD_NUMBER}-${timestamp}"
                    echo "Building Release Tag: ${env.IMAGE_TAG}"
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

        stage('Build & Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh """
                            # Authenticate to Docker Registry
                            echo "\$DOCKER_PASSWORD" | docker login -u "\$DOCKER_USERNAME" --password-stdin ${DOCKER_REGISTRY}

                            # Build image tags
                            docker build -t ${DOCKER_IMAGE}:${env.IMAGE_TAG} -t ${DOCKER_IMAGE}:latest .

                            # Push tags
                            docker push ${DOCKER_IMAGE}:${env.IMAGE_TAG}
                            docker push ${DOCKER_IMAGE}:latest

                            # Clean up registry auth local state
                            docker logout ${DOCKER_REGISTRY}
                        """
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
                        sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${env.IMAGE_TAG}|g' k8s/deployment.yaml
                        
                        # Commit and push changes back to main branch for Argo CD sync
                        git add k8s/deployment.yaml
                        git commit -m "chore(ci): update deployment image tag to ${env.IMAGE_TAG} [skip ci]" || exit 0
                        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${GIT_REPO_URL} HEAD:main
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded! Argo CD will detect commit ${env.IMAGE_TAG} and auto-sync to Kubernetes."
            script {
                sendSlackNotification("SUCCESS", "Pipeline built successfully. Manifest updated to tag `${env.IMAGE_TAG}`. Waiting for Argo CD sync.")
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
        script {
            def color = (status == 'SUCCESS') ? '#36a64f' : 'danger'
            def payload = """{
                "attachments": [
                    {
                        "color": "${color}",
                        "title": "Jenkins CI: ${status}",
                        "text": "${message}",
                        "fields": [
                            { "title": "Job", "value": "${env.JOB_NAME}", "short": true },
                            { "title": "Build", "value": "#${env.BUILD_NUMBER}", "short": true }
                        ]
                    }
                ]
            }"""
            
            sh script: """
                curl -s -X POST -H 'Content-Type: application/json' \
                     --data '${payload.replace('\n', '')}' \
                     "\$WEBHOOK_URL"
            """, returnStdout: false
        }
    }
}
