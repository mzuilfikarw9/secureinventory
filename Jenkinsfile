
pipeline {
    agent any

    options {
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
      
        
        stage('Secret Scan') {
            steps {
                sh '''
                    set -eu
                    gitleaks detect \
                        --source . \
                        --redact \
                        --exit-code 1
                '''
            }
        }


        stage('Unit Tests') {
            steps {
                sh '''
                    set -eu
                    python3 -m venv .venv-ci
                    .venv-ci/bin/python -m pip install \
                        -r requirements-dev.lock
                    .venv-ci/bin/python -m pytest tests -q
                '''
            }
        }
    }

    post {
        always {
            echo 'SecureInventory pipeline finished.'
        }
    }
}

