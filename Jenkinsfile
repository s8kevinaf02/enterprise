pipeline {
  agent any

  triggers {
    githubPush()
  }
  environment {
    AWS_REGION   = "eu-west-2"
    CLUSTER_NAME = "enterprise-eks"
    ECR_REPO     = "enterprise-app-01"
  }

  parameters {
    string(name: 'APP_TAG', defaultValue: 'app1.1.0', description: 'Docker image tag')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Sanity: tools & identity') {
      steps {
        bat """
          aws --version
          docker version
          kubectl version --client
          terraform -version
          aws sts get-caller-identity
        """
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          def repo = "${env.ECR_REPO}".toLowerCase()
          def localImage = "${repo}:${params.APP_TAG}"

          bat """
            docker build -t ${localImage} .
          """
        }
      }
    }

    stage('Login & Push to ECR') {
      steps {
        script {
          def repo = "${env.ECR_REPO}".toLowerCase()
          def localImage = "${repo}:${params.APP_TAG}"

          bat """
            for /f "delims=" %%A in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%A
            set ECR=%ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

            aws ecr describe-repositories --repository-names ${repo} --region %AWS_REGION% >nul 2>nul
            if errorlevel 1 aws ecr create-repository --repository-name ${repo} --region %AWS_REGION%

            rem PowerShell-safe ECR login (avoid piping quirks)
            powershell -NoProfile -Command "$pw = (aws ecr get-login-password --region %AWS_REGION%); docker login --username AWS --password $pw %ECR%"

            docker tag ${localImage} %ECR%/${repo}:${params.APP_TAG}
            docker push %ECR%/${repo}:${params.APP_TAG}

            echo ECR_IMAGE=%ECR%/${repo}:${params.APP_TAG} > image.env
          """
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        bat """
          rem Use workspace kubeconfig so Jenkins service account is consistent
          if not exist "%WORKSPACE%\\.kube" mkdir "%WORKSPACE%\\.kube"
          set KUBECONFIG=%WORKSPACE%\\.kube\\config

          for /f "tokens=1,2 delims==" %%A in (image.env) do set %%A=%%B

          aws eks update-kubeconfig --region %AWS_REGION% --name %CLUSTER_NAME% --kubeconfig "%KUBECONFIG%"

          rem Apply manifests: inject image
          powershell -NoProfile -Command "(Get-Content k8s\\deployment.yaml) -replace 'IMAGE_PLACEHOLDER','%ECR_IMAGE%' | kubectl apply -f -"
          kubectl apply -f k8s\\service.yaml

          kubectl rollout status deployment/enterprise-web
          kubectl get svc enterprise-web-svc -o wide
        """
      }
    }
  }
}
