pipeline {
  agent { label 'docker' }
  options { timestamps(); disableConcurrentBuilds() }
  environment {
    AWS_REGION = 'us-east-1'
    ECR        = "${env.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/sample-service"
    IMAGE      = "${ECR}:${env.GIT_COMMIT}"
  }
  stages {
    stage('Lint & Test') {
      steps {
        sh 'pip install -r requirements.txt ruff && ruff check . && pytest -q --junitxml=reports/junit.xml'
      }
      post { always { junit 'reports/junit.xml' } }
    }
    stage('Security Gates') {
      parallel {
        stage('SAST')  { steps { sh 'pip install bandit && bandit -r app -lll' } }
        stage('SCA')   { steps { sh 'pip install pip-audit && pip-audit -r requirements.txt' } }
        stage('IaC')   { steps { sh 'pip install checkov && checkov -d terraform --quiet --skip-check CKV_TF_1' } }
      }
    }
    stage('Build & Scan Image') {
      steps {
        sh 'docker build -t $IMAGE .'
        sh 'trivy image --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed $IMAGE'
      }
    }
    stage('Push') {
      when { branch 'main' }
      steps {
        sh 'aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR%/*}'
        sh 'docker push $IMAGE'
      }
    }
    stage('Deploy dev')     { when { branch 'main' } steps { deploy('dev') } }
    stage('Deploy staging') { when { branch 'main' } steps { deploy('staging') } }
    stage('Deploy prod') {
      when { branch 'main' }
      steps {
        input message: 'Promote to production?', submitter: 'release-managers'
        deploy('prod')
      }
    }
  }
}

def deploy(String envName) {
  sh """
    aws eks update-kubeconfig --name platform-${envName}
    sed 's|IMAGE_PLACEHOLDER|${IMAGE}|' k8s/deployment.yaml | kubectl apply -n app -f -
    kubectl apply -n app -f k8s/service.yaml
    kubectl rollout status deploy/sample-service -n app --timeout=180s
  """
}
