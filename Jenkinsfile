
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

        stage('SCA Scan') {
            steps {
                sh '''
                    set -eu
                    osv-scanner scan source \
                        --lockfile requirements.txt:requirements.lock
                    osv-scanner scan source \
                        --lockfile requirements.txt:requirements-dev.lock
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

        stage('Container Build') {
            steps {
                sh '''
                    set -eu
                    docker build -t secureinventory:${BUILD_NUMBER} .
                '''
            }
        }

        
        stage('Container Scan') {
            steps {
                sh '''
                    set -eu

                    echo "=== Report High and Critical ==="
                    trivy image \
                    --scanners vuln \
                    --severity HIGH,CRITICAL \
                    secureinventory:${BUILD_NUMBER}

                    echo "=== Enforce Critical Policy ==="
                    trivy image \
                    --scanners vuln \
                    --severity CRITICAL \
                    --exit-code 1 \
                    secureinventory:${BUILD_NUMBER}
                '''
             }
        }


    post {
        always {
            echo 'SecureInventory pipeline finished.'
        }
    }
}
