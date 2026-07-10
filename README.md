![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20ECR-orange)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS%20Auto%20Mode-326CE5?logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)
![OIDC](https://img.shields.io/badge/Auth-OIDC-success)

# EKS Cloud-Native CI/CD Pipeline: Random Name Generator

## Overview

This repository demonstrates a complete cloud-native deployment of the **Random Name Generator and Saver** application on Amazon EKS Auto Mode.

The project includes an automated CI/CD pipeline, passwordless AWS authentication using GitHub OIDC, infrastructure provisioning with Terraform, container deployment to Amazon EKS, and persistent MongoDB storage using a Kubernetes StatefulSet and Amazon EBS Persistent Volumes.

## Cloud Architecture

```mermaid
graph TD
    Developer([Developer]) -->|git push| GitHub[GitHub Actions CI/CD]

    subgraph AWS Cloud
        GitHub -->|OIDC Auth + Push Image| ECR[(Amazon ECR)]

        subgraph EKS Cluster
            GitHub -.->|kubectl apply| EKS_API[EKS API]
            NLB[Network Load Balancer]
            NLB -->|HTTP Port 80 to 8080| APP[Random Name Generator Deployment<br/>3 Replicas]
            APP -->|MongoDB URL TCP 27017| Mongo[(MongoDB StatefulSet<br/>1 Replica)]
            Mongo --- EBS[EBS gp3 Persistent Volume]
        end

        ECR -.->|Image Pull| APP
    end

    User([End User]) -->|HTTP| NLB
```

## Tech Stack

- **Cloud Provider:** AWS: Amazon EKS, Amazon ECR, IAM, NLB, EBS
- **Infrastructure as Code:** Terraform
- **Containerization:** Docker
- **Container Orchestration:** Kubernetes
- **CI/CD:** GitHub Actions
- **Authentication:** GitHub OIDC
- **Database:** MongoDB 3.6

## CI/CD Pipeline Workflow

- **Push:** A developer pushes changes to the `main` branch.
- **Authenticate:** GitHub Actions authenticates to AWS using GitHub OIDC.
- **Build:** Docker builds a new container image.
- **Push:** The image is tagged with the Git commit SHA and pushed to Amazon ECR.
- **Deploy:** GitHub Actions applies the Kubernetes manifests and updates the application image.
- **Verify:** The workflow waits until MongoDB and the application are rolled out successfully.

## Repository Structure

- `.github/workflows/main.yml` - GitHub Actions CI/CD pipeline.
- `terraform/` - Terraform configuration for EKS Auto Mode, VPC, IAM, ECR and GitHub OIDC.
- `k8s/` - Kubernetes manifests for the application, MongoDB StatefulSet, services and StorageClass.
- `docs/architecture.drawio` - draw.io architecture diagram.
- `screenshots/` - Project screenshots documenting the infrastructure, pipeline and running app.

## How to Deploy and Trigger the Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/KeterNoam/DevOps-Project-final.git
cd DevOps-Project-final
```

### 2. Set Your GitHub Repository in Terraform

Edit `terraform/variables.tf` and replace:

```hcl
default = "KeterNoam/DevOps-Project-final"
```

with your real GitHub owner and repository name.

### 3. Provision the Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Terraform provisions:

- Amazon EKS Auto Mode cluster
- Amazon VPC
- Public and private subnets
- Internet Gateway and NAT Gateway
- Amazon ECR repository
- GitHub OIDC identity provider
- IAM role for GitHub Actions
- EKS access entry for CI/CD deployment

### 4. Configure GitHub Actions Secret

After `terraform apply`, copy the `github_actions_role_arn` output and create this GitHub repository secret:

| Secret Name | Value |
| --- | --- |
| `AWS_ROLE_TO_ASSUME` | Terraform output: `github_actions_role_arn` |

### 5. Trigger the Deployment

Push to the `main` branch:

```bash
git add .
git commit -m "Deploy random name generator to EKS"
git push origin main
```

GitHub Actions automatically:

- Authenticates to AWS using OIDC
- Builds the Docker image
- Pushes the image to Amazon ECR
- Deploys MongoDB as a StatefulSet
- Deploys the Random Name Generator application
- Updates the application image
- Waits for rollout completion

### 6. Verify the Deployment

Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-app-cluster
```

Check Kubernetes resources:

```bash
kubectl get nodes
kubectl get deployments
kubectl get statefulsets
kubectl get pods
kubectl get svc
kubectl get pvc
kubectl get storageclass
kubectl get all
```

Get the public application endpoint:

```bash
kubectl get svc namegen-service
```

## Application Configuration

The application uses the required MongoDB connection string:

```text
MONGODB_URL=mongodb://genuser:password@mongodb/namegen
```

The Node.js application listens on port `8080`, and the Network Load Balancer exposes it externally on port `80`.

## Project Screenshots

The `screenshots/` directory should contain evidence of the final deployment:

- Terraform files and successful Terraform apply
- EKS cluster created
- ECR repository and pushed image
- GitHub Actions workflow success
- Running Kubernetes pods, services and PVC
- Application running through the Network Load Balancer
- Random name saved and displayed from MongoDB

## Local Docker Test

```bash
docker build -t namegen:local .
docker run --rm -p 8080:8080 \
  -e MONGODB_URL=mongodb://genuser:password@mongodb/namegen \
  namegen:local
```

## Notes

- The Docker image is built from the application source code in the repository root.
- MongoDB runs as a Kubernetes StatefulSet with persistent storage.
- The public application endpoint is created by a Kubernetes `LoadBalancer` service backed by an AWS Network Load Balancer.
- CI/CD uses GitHub OIDC, so no long-lived AWS access keys are stored in GitHub.
