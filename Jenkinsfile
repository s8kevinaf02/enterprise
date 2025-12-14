pipeline {
    agent any

    environment {
        DOCKER_HUB_USERNAME = "s8kevinaf02"
        ALPHA_APPLICATION_01_REPO = "enterprise-App-01"
    }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: '')
        string(name: 'APP1_TAG', defaultValue: 'app1.1.0', description: '')
        string(name: 'PORT_ON_DOCKER_HOST_01', defaultValue: '3000', description: '')
        string(name: 'CONTAINER_NAME', defaultValue: 'enterprise-App-01', description: '')
    }

    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Checking the code') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'echo Hello from Linux agent'
                    } else {
                        bat 'echo Hello from Windows agent'
                    }
                }
            }
        }

        stage('Building application 01') {
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            docker build -t ${DOCKER_HUB_USERNAME}/${ALPHA_APPLICATION_01_REPO}:${params.APP1_TAG} .
                            docker images | grep ${params.APP1_TAG}
                        """
                    } else {
                        bat """
                            docker build -t ${DOCKER_HUB_USERNAME}/${ALPHA_APPLICATION_01_REPO}:${params.APP1_TAG} .
                            docker images | findstr ${params.APP1_TAG}
                        """
                    }
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', 
                                                  usernameVariable: 'DOCKER_HUB_USERNAME', 
                                                  passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
                    script {
                        if (isUnix()) {
                            sh """
                                echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
                            """
                        } else {
                            bat """
                                echo %DOCKER_HUB_PASSWORD% | docker login -u %DOCKER_HUB_USERNAME% --password-stdin
                            """
                        }
                    }
                }
            }
        }

        stage('Pushing images to Docker Hub') {
            steps {
                script {
                    if (isUnix()) {
                        sh "docker push ${DOCKER_HUB_USERNAME}/${ALPHA_APPLICATION_01_REPO}:${params.APP1_TAG}"
                    } else {
                        bat "docker push ${DOCKER_HUB_USERNAME}/${ALPHA_APPLICATION_01_REPO}:${params.APP1_TAG}"
                    }
                }
            }
        }

        stage('Deploying the application 01') {
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            docker run -itd -p ${params.PORT_ON_DOCKER_HOST_01}:80 --name ${params.CONTAINER_NAME} ${DOCKER_HUB_USERNAME}/${ALPHA_APPLICATION_01_REPO}:${params.APP1_TAG}
                            docker ps | grep ${params.CONTAINER_NAME}
                        """
                    } else {
                        bat """
                            docker run -itd -p ${params.PORT_ON_DOCKER_HOST_01}:80 --name ${params.CONTAINER_NAME} ${DOCKER_HUB_USERNAME}/${ALPHA_APPLICATION_01_REPO}:${params.APP1_TAG}
                            docker ps | findstr ${params.CONTAINER_NAME}
                        """
                    }
                }
            }
        }
    }
}
