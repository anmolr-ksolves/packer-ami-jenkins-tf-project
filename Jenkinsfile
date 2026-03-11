pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'AWS region for Packer and Terraform')
    string(name: 'KEY_NAME', defaultValue: 'anmol-keypair', description: 'Existing EC2 key pair name')
    string(name: 'TERRAFORM_DIR', defaultValue: 'terraform', description: 'Directory that contains Terraform code')
  }

  environment {
    AWS_REGION = "${params.AWS_REGION}"
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    TF_VAR_region = "${params.AWS_REGION}"
    TF_VAR_key_name = "${params.KEY_NAME}"
    TF_IN_AUTOMATION = "true"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Verify Tooling') {
      steps {
        sh '''
          bash -lc '
            set -euo pipefail
            aws --version
            packer version
            terraform version
            jq --version
          '
        '''
      }
    }

    stage('Packer Init') {
      steps {
        withCredentials([
          string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir('packer') {
            sh '''
              bash -lc '
                set -euo pipefail
                export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_REGION
                packer init .
              '
            '''
          }
        }
      }
    }

    stage('Packer Validate') {
      steps {
        withCredentials([
          string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir('packer') {
            sh '''
              bash -lc '
                set -euo pipefail
                export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_REGION
                packer validate .
              '
            '''
          }
        }
      }
    }

    stage('Packer Build AMI') {
      steps {
        withCredentials([
          string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir('packer') {
            sh '''
              bash -lc '
                set -euo pipefail
                export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_REGION
                packer build .
              '
            '''
          }
        }
      }
    }

    stage('Extract AMI ID') {
      steps {
        script {
          env.AMI_ID = sh(
            script: '''
              bash -lc '
                set -euo pipefail
                jq -r ".builds[-1].artifact_id" packer/manifest.json | cut -d: -f2
              '
            ''',
            returnStdout: true
          ).trim()

          if (!env.AMI_ID) {
            error('Failed to extract AMI_ID from packer/manifest.json')
          }

          echo "AMI_ID=${env.AMI_ID}"
        }
      }
    }

    stage('Store AMI in SSM') {
      steps {
        withCredentials([
          string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            bash -lc '
              set -euo pipefail
              export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_REGION
              aws ssm put-parameter \
                --name "/nginx/latest-ami" \
                --type String \
                --value "$AMI_ID" \
                --overwrite
            '
          '''
        }
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([
          string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir("${params.TERRAFORM_DIR}") {
            sh '''
              bash -lc '
                set -euo pipefail
                export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_REGION TF_VAR_region TF_VAR_key_name
                terraform init -input=false
              '
            '''
          }
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        withCredentials([
          string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir("${params.TERRAFORM_DIR}") {
            sh '''
              bash -lc '
                set -euo pipefail
                export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_REGION TF_VAR_region TF_VAR_key_name
                terraform validate
              '
            '''
          }
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([
          string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir("${params.TERRAFORM_DIR}") {
            sh '''
              bash -lc '
                set -euo pipefail
                export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_REGION TF_VAR_region TF_VAR_key_name
                terraform apply -auto-approve -input=false
              '
            '''
          }
        }
      }
    }
  }
}
