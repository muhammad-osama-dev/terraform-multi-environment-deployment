# Terraform Multi-Environment Infrastructure Deployment


## Introduction

This project demonstrates how to use Terraform to deploy infrastructure across multiple environments, specifically dev and prod, in different AWS regions (us-east-1 and eu-central-1). It also includes setting up network resources within a dedicated network module and using local-exec provisioners to print the public IP of a bastion EC2 instance.

## Table of Contents

1. [Project Structure](#project-structure)
    - [AWS CLI Configuration](#aws-cli-coniguration)
    - [Environments](#environments)
    - [Network Module](#network-module)
    - [Deployment](#deployment)
    - [Local-Exec Provisioner](#local-exec-provisioner)
2. [GitHub Repository](#github-repository)
3. [Continuous Integration/Continuous Deployment (CI/CD)](#continuous-integrationcontinuous-deployment-cicd)
    - [Jenkins Integration](#jenkins-intergration)
4. [Email Notifications](#email-notifications)
    - [Email Verification with Amazon SES](#email-verification-with-amazon-ses)
    - [Lambda Function for Notifications](#lambda-function-for-notifications)
6. [Trigger and Email Notifications](#trigger-and-email-notifications)

## Project Structure

This project is organized into different components:

### AWS CLI Configuration

Before you begin deploying infrastructure with Terraform, you need to configure your AWS CLI credentials. Follow these steps to configure AWS CLI:

1. Open your terminal or command prompt.

2. Run the following command to start the configuration process:

   ```bash
   aws configure
   ```

3. You will be prompted to enter the following information:

   - **AWS Access Key ID:** Enter your AWS Access Key ID.
   - **AWS Secret Access Key:** Enter your AWS Secret Access Key.
   - **Default region name:** Enter the default AWS region you want to use (e.g., `us-east-1` or `eu-central-1`).
   - **Default output format:** You can leave this as the default value or enter `json` for JSON output.

4. After entering the required information, AWS CLI will save your configuration.

   Your AWS CLI is now configured, and you are ready to use Terraform to deploy infrastructure to your AWS account.

   **Important:** Be extremely cautious with your AWS credentials. Never share them publicly or expose them in your code repositories. It's recommended to use IAM roles and policies to manage permissions securely.

   For more information on AWS CLI configuration and best practices, refer to the [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

Now that you have your AWS CLI configured, you can proceed with setting up your Terraform project and deploying infrastructure across different environments.

### Environments

Two workspaces, `dev` and `prod`, are created to manage infrastructure deployments separately. Corresponding variable definition files (`dev.tfvars` and `prod.tfvars`) hold environment-specific configurations.

#### How to create workspaces?

showing workspaces 
```bash
terraform workspace list
```
create dev workspace
```bash
terraform workspace new dev
```
create prod workspace
```bash
terraform workspace new prod
```

Declaring variables and default values 
#### variables.tf
default values if environment is not specified 
```hcl
variable "region" {
  type = string
  default = "eu-central-1"
}

variable "ami" {
    type = string
    default = "ami-04e601abe3e1a910f"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "vpc_cidr" {
  description = "cidr for vpc"
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_configs" {
  description = "Configuration for public subnets"
  type        = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
  default = {
    public_subnet1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "eu-central-1a"
      name              = "public_subnet1"
    },
    public_subnet2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "eu-central-1b"
      name              = "public_subnet2"
    }
    private_subnet1 = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "eu-central-1a"
      name              = "private_subnet1"
    },
    private_subnet2 = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "eu-central-1b"
      name              = "private_subnet2"
    }
  }
}
```
values for each workspace assigned at .tfvars
#### dev.tfvars 
```hcl
region = "eu-central-1"
ami = "ami-04e601abe3e1a910f"
instance_type = "t2.micro"
vpc_cidr = "10.0.0.0/16"
subnet_configs = {
    public_subnet1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "eu-central-1a"
      name              = "public_subnet1"
    },
    public_subnet2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "eu-central-1b"
      name              = "public_subnet2"
    }
    private_subnet1 = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "eu-central-1a"
      name              = "private_subnet1"
    },
    private_subnet2 = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "eu-central-1b"
      name              = "private_subnet2"
    }
  }
```
#### prod.tfvars 
```hcl
region = "us-east-1"
ami = "ami-053b0d53c279acc90"
instance_type = "t2.micro"
vpc_cidr = "10.0.0.0/16"
subnet_configs = {
    public_subnet1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      name              = "us_public_subnet1"
    },  
    public_subnet2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
      name              = "us_public_subnet2"
    }
    private_subnet1 = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1a"
      name              = "us_private_subnet1"
    },
    private_subnet2 = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-east-1b"
      name              = "us_private_subnet2"
    }
  }
```

select workspace

for dev workspace 
```bash
terraform workspace select dev 
```
apply 
```bash
terraform apply -var-file dev.tfvars 
```
Infrastructure 
![Sample Image](./screenshots/frankfurt-vpc.png)
![Sample Image](./screenshots/frankfurt-vpc1.png)
![Sample Image](./screenshots/frankfurst-vpc-private1.png)


### Network Module

1. Network resources are organized within a reusable network module to ensure consistent configurations across environments.
2. create input variables (variables.tf) to map the *.tfvars to the network module  
#### variables.tf 
```hcl
variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_configs" {
  description = "Configuration for subnets"
  type        = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
  default = {
    public_subnet1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "eu-central-1a"
      name              = "public_subnet1"
    },
    public_subnet2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "eu-central-1b"
      name              = "public_subnet2"
    },
    private_subnet1 = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "eu-central-1a"
      name              = "private_subnet1"
    },
    private_subnet2 = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "eu-central-1b"
      name              = "private_subnet2"
    }
  }
}
```
3. create output variable to access resources created in the module 
```hcl
variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_configs" {
  description = "Configuration for subnets"
  type        = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
  default = {
    public_subnet1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "eu-central-1a"
      name              = "public_subnet1"
    },
    public_subnet2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "eu-central-1b"
      name              = "public_subnet2"
    },
    private_subnet1 = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "eu-central-1a"
      name              = "private_subnet1"
    },
    private_subnet2 = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "eu-central-1b"
      name              = "private_subnet2"
    }
  }
}
```

4. create network module to expose needed variables outside the network module
```hcl
module "network" {
  source = "./network"
  region = var.region
  vpc_cidr = var.vpc_cidr
  subnet_configs = var.subnet_configs
}
```

### Deployment

The Terraform code deploys infrastructure to AWS regions `us-east-1` and `eu-central-1` based on the selected workspace (environment).

#### To deploy 

1. select workspace

for dev workspace (eu-central-1)
```bash
terraform workspace select dev 
```
2. apply 
```bash
terraform apply -var-file dev.tfvars 
```
Infrastructure 
![Sample Image](./screenshots/instances.png)
![Sample Image](./screenshots/frankfurt-vpc.png)
![Sample Image](./screenshots/frankfurt-vpc1.png)
![Sample Image](./screenshots/frankfurst-vpc-private1.png)


### Local-Exec Provisioner

A local-exec provisioner is used to execute a command that prints the public IP of the bastion EC2 instance after deployment.

![Sample Image](./screenshots/instances.png)
![Sample Image](./screenshots/inventory.png)

## GitHub Repository

The infrastructure code is uploaded to a GitHub repository for version control and collaboration.

## Continuous Integration/Continuous Deployment (CI/CD)

A Jenkins image with Terraform installed is created for CI/CD pipelines. A pipeline is configured to accept an environment parameter and apply the Terraform code to the selected environment.
### Steps:
1. Create a Dockerfile
2. add the following code 
```hcl
FROM jenkins/jenkins:latest

USER root

RUN apt-get update && apt-get install -y curl unzip

RUN curl -LO https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip && \
    unzip terraform_1.5.7_linux_amd64.zip -d /usr/local/bin/ && \
    rm terraform_1.5.7_linux_amd64.zip
```
3. build the docker image 

```bash
docker build -t <image-name> .
```
4. run the docker container 
- port map 8080 for jenkins 
- port map 50000 for terraform
```bash
docker run -d -p 8080:8080 -p 50000:50000 --name <container-name> <image-name>
```
5. access jenkins through http://localhost:8080

6. enter the docker container to get the password 
```bash
docker exec -it <container-name> /bin/bash
```

```bash
cat /var/jenkins_home/secrets/initialAdminPassword
```

### Jenkins 
1. create pipeline with the following code 
```bash
pipeline {
    agent any
    parameters {
        choice(name: 'env', choices: ["dev", "prod"], description: 'Select environment')
    }
    environment {
        AWS_CREDENTIALS = credentials('08f2e8f4-4b89-4190-a2de-b1341dac11f8') 
        TF_ENV = "${params.env}"
        ENV_VAR_FILE = "${TF_ENV}.tfvars"  
    }
    stages {
        stage('List Workspaces') {
            steps {
                script {
                    def workspaceName = TF_ENV
                    def workspaceExists = sh(script: "terraform workspace list | grep -q $workspaceName", returnStatus: true)
                    
                    if (workspaceExists != 0) {
                        sh "terraform workspace new $workspaceName"
                    } else {
                        echo "Workspace $workspaceName already exists."
                    }
                }
            }
        }
        stage('Checkout Code') {
            steps {
                git(
                    url: "https://github.com/muhammad-osama-dev/iti-terraform-lab2.git",
                    branch: "main",
                    poll: true
                )
            }
        }
        stage('Terraform Deployment') {
            steps {
                script {
                    def envVarFile = "${TF_ENV}.tfvars"
                    sh 'terraform init'
                    sh "terraform workspace select $TF_ENV"
                    sh "terraform plan -var-file=${envVarFile}"
                    sh "terraform apply -var-file=${envVarFile} -auto-approve"
                }
            }
        }
    }
}
```
2. choose build with parameters 
3. choose environment 
![image](./screenshots/choosing-dev-env.png)






## Email Notifications

Amazon SES is used to verify email addresses for sending notifications.
![image](./screenshots/email-verifying1.png)
### Email Verification with Amazon SES

![image](./screenshots/email-verifcation.png)

### Lambda Function for Notifications

A Lambda function is created to send email notifications when there are changes in the Terraform state files.
```python
import boto3

def lambda_handler(event, context):
    ses = boto3.client('ses', region_name='eu-central-1')
    sender_email = 'mohamedelshafei977@gmail.com'
    recipient_email = 'mohamedelshafei977@gmail.com'
    subject = 'Hello'
    body = "it is 2AM"
    response = ses.send_email(
        Source=sender_email,  # Corrected variable name
        Destination={
            'ToAddresses': [
                recipient_email,
            ],
        },
        Message={
            'Subject': {
                'Data': subject,
            },
            'Body': {
                'Text': {
                    'Data': body,
                },
            },
        },
    )

    return {
        'statusCode': 200,
        'body': 'Email sent successfully.',
    }
```

## Trigger and Email Notifications

A trigger mechanism is implemented to detect changes in the Terraform state files and send email notifications using the Lambda function and SES.
![image](./screenshots/lamda-and-s3.png)

getting emails when triggering a build 
![image](./screenshots/when-triggering-build.png)
![image](./screenshots/got-email.png)
Refer to individual sections and the provided Terraform code for more details on each component.
## Getting Started

To get started, follow these steps:

1. Set up AWS credentials.
2. Clone this repository.
3. Configure the desired environment using `.tfvars` files.
4. Apply Terraform code using Jenkins or the command line.
5. Monitor changes and receive email notifications for state file changes.

## Contributing

Contributions to this project are welcome. Feel free to open issues or pull requests.

## License

This project is licensed under the [MIT License](LICENSE).


