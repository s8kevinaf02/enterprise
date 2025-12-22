pipeline {
  agent any

  triggers {
    githubPush()
  }

  environment {
    AWS_REGION   = "eu-west-2"
    CLUSTER_NAME = "enterprise-eks"
    ECR_REPO     = "enterprise-app-01"
    KUBECTL_EXE  = "C:\\kubectl\\kubectl.exe"
  }

  parameters {
    string(name: 'APP_TAG', defaultValue: 'app1.1.0', description: 'Docker image tag')
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Sanity') {
      steps {
        bat """
          echo ==== TOOLS ====
          aws --version
          docker version
          "%KUBECTL_EXE%" version --client
        """
      }
    }

    stage('Build Docker image') {
      steps {
        bat """
          docker build -t %ECR_REPO%:%APP_TAG% .
        """
      }
    }

    stage('Login & Push to ECR') {
      steps {
        withCredentials([
          string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          bat """
            set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
            set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
            set AWS_REGION=%AWS_REGION%

            for /F "delims=" %%A in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%A
            set ECR=%ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

            aws ecr describe-repositories --repository-names %ECR_REPO% --region %AWS_REGION% >nul 2>nul
            if errorlevel 1 aws ecr create-repository --repository-name %ECR_REPO% --region %AWS_REGION%

            aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR%

            docker tag %ECR_REPO%:%APP_TAG% %ECR%/%ECR_REPO%:%APP_TAG%
            docker push %ECR%/%ECR_REPO%:%APP_TAG%

            echo ECR_IMAGE=%ECR%/%ECR_REPO%:%APP_TAG% > image.env
          """
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        withCredentials([
          string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          bat """
            set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
            set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
            set AWS_REGION=%AWS_REGION%

            if not exist "%WORKSPACE%\\.kube" mkdir "%WORKSPACE%\\.kube"
            set KUBECONFIG=%WORKSPACE%\\.kube\\config

            aws eks update-kubeconfig --region %AWS_REGION% --name %CLUSTER_NAME% --kubeconfig "%KUBECONFIG%"

            for /F "tokens=1,2 delims==" %%A in (image.env) do set %%A=%%B

            powershell -NoProfile -Command ^
              "(Get-Content 'k8s\\deployment.yaml') -replace 'IMAGE_PLACEHOLDER','%ECR_IMAGE%' | Set-Content 'k8s\\deployment.rendered.yaml'"

            "%KUBECTL_EXE%" apply -f k8s\\deployment.rendered.yaml
            "%KUBECTL_EXE%" apply -f k8s\\service.yaml
            "%KUBECTL_EXE%" rollout status deployment/enterprise-web
            "%KUBECTL_EXE%" get svc enterprise-web-svc -o wide
          """
        }
      }
    }
  }
}
