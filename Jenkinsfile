pipeline { 
    agent any 
 
    environment { 
        ACCOUNT_ID = "465853823370" 
        AWS_REGION = "eu-north-1" 
        IMAGE_NAME = "java25-demo-app" 
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}" 
    } 

    stages { 
 
        stage('1. Checkout Code') { 
            steps { 
                git branch: 'main', 
                url: 'https://github.com/nithinvarma-git/java-example-varma-jar.git' 
            } 
        }

        stage('2. Build Docker Image') { 
            steps { 
                sh ''' 
                    docker build -t $IMAGE_NAME:$BUILD_NUMBER . 
                ''' 
            } 
        } 

       stage('Trivy Image Scan') {
    steps {
        sh '''
            set -e

            echo "Workspace: $(pwd)"
            ls -lah

            mkdir -p $HOME/trivy-cache

            IMAGE=$IMAGE_NAME:$BUILD_NUMBER

            echo "Scanning image: $IMAGE"

            trivy image --scanners vuln \
                --cache-dir $HOME/trivy-cache \
                --no-progress \
                -f table \
                -o trivy-image-report.txt \
                $IMAGE

            ls -lah trivy-image-report.txt || true
        '''
    }
    }  
     stage('4. AWS ECR Login') { 
            steps { 
                withCredentials([[ 
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'aws-cred' 
                ]]) { 
                    sh ''' 
                        aws ecr get-login-password --region $AWS_REGION | \ 
                        docker login \ 
                        --username AWS \ 
                        --password-stdin \ 
                        $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com 
                    ''' 
                } 
            } 
        }

     stage('5. Tag Docker Image') { 
            steps { 
                sh ''' 
                    docker tag $IMAGE_NAME:$BUILD_NUMBER 
$ECR_REPO:$BUILD_NUMBER 
                ''' 
            } 
        } 
 
        stage('6. Push Image to ECR') { 
            steps { 
                sh ''' 
                    docker push $ECR_REPO:$BUILD_NUMBER 
                ''' 
            } 
        } 
 
        stage('7. Pull Image from ECR') { 
            steps { 
                sh ''' 
                    docker pull $ECR_REPO:$BUILD_NUMBER 
                ''' 
            } 
        } 
 
        stage('8. Deploy Container') { 
            steps { 
                sh ''' 
                    docker stop java25-container || true 
                    docker rm java25-container || true 
 
                    docker run -d \ 
                    --name java25-container \ 
                    -p 8085:8080 \ 
                    $ECR_REPO:$BUILD_NUMBER 
                ''' 
            } 
        } 
    } 
 
    post { 
        always { 
            archiveArtifacts artifacts: 'trivy-image-report.html', allowEmptyArchive: true 
        } 
    } 
} 


