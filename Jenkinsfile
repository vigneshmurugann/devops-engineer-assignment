pipeline {
  agent any

  environment {
    REGISTRY = 'docker.io'
    DOCKERHUB_USER = credentials('dockerhub-username')
    DOCKERHUB_TOKEN = credentials('dockerhub-token')
    API_IMAGE = "${REGISTRY}/${DOCKERHUB_USER}/devops-api:${BUILD_NUMBER}"
    WEB_IMAGE = "${REGISTRY}/${DOCKERHUB_USER}/devops-web:${BUILD_NUMBER}"
  }

  stages {
    stage('Checkout Source') {
      steps {
        checkout scm
      }
    }

    stage('Lint') {
      steps {
        sh 'python3 -m py_compile apps/api/main.py'
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'python3 -m pip install -r apps/api/requirements.txt'
        sh 'cd apps/api && python3 -m pytest'
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t ${API_IMAGE} apps/api'
        sh 'docker build -t ${WEB_IMAGE} apps/web'
      }
    }

    stage('Security Scan') {
      steps {
        sh 'trivy image --exit-code 1 --severity CRITICAL ${API_IMAGE}'
        sh 'trivy image --exit-code 1 --severity CRITICAL ${WEB_IMAGE}'
      }
    }

    stage('Push Image') {
      steps {
        sh 'echo ${DOCKERHUB_TOKEN} | docker login -u ${DOCKERHUB_USER} --password-stdin'
        sh 'docker push ${API_IMAGE}'
        sh 'docker push ${WEB_IMAGE}'
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh 'kubectl apply -k k8s/overlays/dev'
        sh 'kubectl -n devops-app set image deployment/api api=${API_IMAGE}'
        sh 'kubectl -n devops-app set image deployment/web web=${WEB_IMAGE}'
      }
    }

    stage('Post-Deployment Validation') {
      steps {
        sh 'kubectl -n devops-app rollout status deployment/api --timeout=180s'
        sh 'kubectl -n devops-app rollout status deployment/web --timeout=180s'
        sh 'kubectl -n devops-app get pods'
      }
    }
  }

  post {
    failure {
      echo 'Pipeline failed. Check lint, tests, Trivy results, and rollout events.'
    }
  }
}
