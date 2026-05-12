pipeline {
    agent any

    environment {
        ACCOUNT_ID = "465853823370"
        AWS_REGION = "eu-north-1"
        IMAGE_NAME = "java25-demo-app"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"
    }

    stages {

        stage('1. Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/nithinvarma-git/java-example-varma-jar.git'
            }
        }

        stage('2. Maven Build') {
            steps {
                sh """
                    mvn clean package -DskipTests
                """
            }
        }

        stage('3. Build Docker Image') {
            steps {
                sh """
                    docker build -t $IMAGE_TAG .
                """
            }
        }

        stage('4. Trivy Image Scan') {
            steps {
                sh """
                    set -e

                    mkdir -p trivy-cache

                    trivy image --scanners vuln \
                        --cache-dir trivy-cache \
                        --no-progress \
                        -f table \
                        -o trivy-image-report.txt \
                        $IMAGE_TAG

                    ls -lah trivy-image-report.txt || true
                """
            }
        }

        stage('5. AWS ECR Login') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-cred'
                ]]) {
                    sh """
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    """
                }
            }
        }

        stage('6. Tag Docker Image') {
            steps {
                sh """
                    docker tag $IMAGE_TAG $ECR_REPO:$BUILD_NUMBER
                """
            }
        }

        stage('7. Push Image to ECR') {
            steps {
                sh """
                    docker push $ECR_REPO:$BUILD_NUMBER
                """
            }
        }

        stage('8. Pull Image from ECR') {
            steps {
                sh """
                    docker pull $ECR_REPO:$BUILD_NUMBER
                """
            }
        }

        stage('9. Deploy Container') {
            steps {
                sh """
                    docker stop java25-container || true
                    docker rm java25-container || true

                    docker run -d --name java25-container -p 8085:8085 $ECR_REPO:$BUILD_NUMBER
                """
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-image-report.txt', allowEmptyArchive: true
        }
    }
}
