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
      steps {
        checkout scm
      }
    }

    stage('Sanity: tools') {
      steps {
        bat '''
          echo ==== TOOLS CHECK ====
          aws --version
          docker version
          kubectl version --client
        '''
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          def repo = env.ECR_REPO.toLowerCase()
          def localImage = "${repo}:${params.APP_TAG}"
          bat """
            echo ==== BUILD IMAGE ====
            docker build -t ${localImage} .
          """
        }
      }
    }

    stage('Login & Push to ECR') {
      steps {
        withCredentials([
          string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          script {
            def repo = env.ECR_REPO.toLowerCase()
            def localImage = "${repo}:${params.APP_TAG}"

            bat """
              echo ==== AWS CREDS ====
              set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
              set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
              set AWS_REGION=%AWS_REGION%

              aws sts get-caller-identity

              for /F "delims=" %%A in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%A
              set ECR=%ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

              echo ==== ENSURE ECR REPO ====
              aws ecr describe-repositories --repository-names ${repo} --region %AWS_REGION% >nul 2>nul
              if errorlevel 1 aws ecr create-repository --repository-name ${repo} --region %AWS_REGION%

              echo ==== LOGIN TO ECR ====
              aws ecr get-login-password --region %AWS_REGION% > ecr_pw.txt
              type ecr_pw.txt | docker login --username AWS --password-stdin %ECR%
              del ecr_pw.txt

              echo ==== TAG & PUSH ====
              docker tag ${localImage} %ECR%/${repo}:${params.APP_TAG}
              docker push %ECR%/${repo}:${params.APP_TAG}

              echo ECR_IMAGE=%ECR%/${repo}:${params.APP_TAG} > image.env
            """
          }
        }
      }
    }

    stage('Debug kubectl path') {
        steps {
             bat '''
                echo ==== WHERE KUBECTL ====
                where kubectl
            '''
         }
    }


    stage('Deploy to EKS') {
      steps {
        withCredentials([
          string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          bat '''
            echo ==== AWS CREDS ====
            set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
            set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
            set AWS_REGION=%AWS_REGION%

            echo ==== LOAD IMAGE ====
            for /F "tokens=1,2 delims==" %%A in (image.env) do set %%A=%%B
            echo Deploying %ECR_IMAGE%

            echo ==== PREPARE KUBECONFIG ====
            if not exist "%WORKSPACE%\\.kube" mkdir "%WORKSPACE%\\.kube"
            set "KCFG=%WORKSPACE%\\.kube\\config"

            echo ==== UPDATE KUBECONFIG ====
            aws eks update-kubeconfig --region %AWS_REGION% --name %CLUSTER_NAME% --kubeconfig "%KCFG%"

            echo ==== DEPLOY TO K8S ====
            powershell -NoProfile -Command "$env:KUBECONFIG='%KCFG%'; (Get-Content 'k8s\\deployment.yaml') -replace 'IMAGE_PLACEHOLDER','%ECR_IMAGE%' | kubectl apply -f -"
            cmd /V /C "set KUBECONFIG=%KCFG%&& kubectl apply -f k8s\\service.yaml"

            echo ==== ROLLOUT STATUS ====
            cmd /V /C "set KUBECONFIG=%KCFG%&& kubectl rollout status deployment/enterprise-web"
            cmd /V /C "set KUBECONFIG=%KCFG%&& kubectl get svc enterprise-web-svc -o wide"
          '''
        }
      }
    }
  }
}
