pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "gopinathsiva2605"
        DEV_IMAGE = "gopinathsiva2605/dev"
        PROD_IMAGE = "gopinathsiva2605/prod"
        IMAGE_TAG = "${GIT_COMMIT[0..6]}"
    }

    stages {
        stage('Clone') {
            steps {
                echo "Building branch: ${GIT_BRANCH}"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "chmod +x build.sh"
                sh "./build.sh ${GIT_BRANCH}"
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'

                    script {
                        if (env.GIT_BRANCH == 'origin/dev') {
                            echo "Pushing to DEV repo..."
                            sh "docker push ${DEV_IMAGE}:latest"
                        } else if (env.GIT_BRANCH == 'origin/master') {
                            echo "Pushing to PROD repo..."
                            sh "docker tag ${DEV_IMAGE}:latest ${PROD_IMAGE}:latest"
                            sh "docker push ${PROD_IMAGE}:latest"
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'dev'
            }
            steps {
                sh "chmod +x deploy.sh"
                sh "./deploy.sh"
            }
        }
    }

    post {
        success { echo "Pipeline succeeded on branch: ${GIT_BRANCH}" }
        failure { echo "Pipeline failed on branch: ${GIT_BRANCH}" }
    }
}
