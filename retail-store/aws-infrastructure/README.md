# AWS EKS Infrastructure Setup Guide

This guide provides instructions for deploying the Retail Store application on AWS using EKS (Elastic Kubernetes Service) with Terraform.

## Prerequisites

1. **AWS Account**: An active AWS account with appropriate permissions
2. **AWS CLI**: Installed and configured with credentials (`aws configure`)
3. **Terraform**: Version 1.0 or higher
4. **kubectl**: Kubernetes command-line tool
5. **Helm**: Kubernetes package manager (optional, for addon management)
6. **Docker**: For building container images
7. **AWS Services Required**:
   - EKS (Kubernetes clusters)
   - EC2 (Node instances)
   - RDS (Aurora MySQL)
   - ECR (Container Registry)
   - S3 (Static file storage)
   - CloudFront (CDN)
   - CloudWatch (Monitoring)
   - VPC & Networking

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      CloudFront CDN                      │
│              (Frontend Distribution)                     │
└──────────────────────┬──────────────────────────────────┘
                       │
      ┌────────────────┴─────────────────┐
      │                                  │
┌─────▼──────────────────────────────────▼─────┐
│          AWS EKS Cluster                       │
│  (Elastic Kubernetes Service)                  │
├──────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐         │
│  │ Auth Service │  │Product Service         │
│  │  (Pod)       │  │  (Pod)       │         │
│  └──────────────┘  └──────────────┘         │
│                                              │
│  ┌──────────────┐  ┌──────────────┐         │
│  │ Order Service│  │Payment Service         │
│  │  (Pod)       │  │  (Pod)       │         │
│  └──────────────┘  └──────────────┘         │
│                                              │
│  ┌─────────────────────────────────────┐   │
│  │    Node Group (Auto Scaling)        │   │
│  │  EC2 Instances (t3.medium)          │   │
│  └─────────────────────────────────────┘   │
└───────────────────────┬─────────────────────┘
                        │
    ┌───────────────────┴───────────────────┐
    │                                       │
┌───▼────────────────┐      ┌──────────────▼────┐
│  RDS Aurora MySQL  │      │ S3 Frontend Bucket │
│  (Multi-AZ)        │      │ + CloudFront Cache │
└────────────────────┘      └───────────────────┘
```

## Key Differences from ECS

- **EKS** provides managed Kubernetes clusters for better portability
- **Auto-scaling** at the pod level with Horizontal Pod Autoscaler (HPA)
- **Declarative** infrastructure using Kubernetes manifests
- **Multi-cloud compatible** - same manifests work on other Kubernetes distributions
- **Better service discovery** through Kubernetes DNS
- **Built-in monitoring** with kubectl and CloudWatch

## Deployment Steps

### Step 1: Prepare AWS and Local Environment

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm (optional but recommended)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Step 2: Build and Push Docker Images to ECR

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# Log in to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build images
docker build -f docker/Dockerfile.auth -t retail-store-auth-service .
docker build -f docker/Dockerfile.product -t retail-store-product-service .
docker build -f docker/Dockerfile.order -t retail-store-order-service .
docker build -f docker/Dockerfile.payment -t retail-store-payment-service .
docker build -f docker/Dockerfile.frontend -t retail-store-frontend .

# Tag images
docker tag retail-store-auth-service:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-auth-service:latest
docker tag retail-store-product-service:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-product-service:latest
docker tag retail-store-order-service:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-order-service:latest
docker tag retail-store-payment-service:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-payment-service:latest
docker tag retail-store-frontend:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-frontend:latest

# Push images
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-auth-service:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-product-service:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-order-service:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-payment-service:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-frontend:latest
```

### Step 3: Initialize and Plan Terraform

```bash
cd aws-infrastructure

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan infrastructure
terraform plan -out=tfplan
```

### Step 4: Apply Terraform Configuration

```bash
# Apply the infrastructure
terraform apply tfplan

# Save outputs for reference
terraform output -json > outputs.json
```

### Step 5: Configure kubectl

```bash
# Get output commands
KUBECTL_CONFIG_CMD=$(terraform output -raw configure_kubectl)

# Configure kubectl to access EKS cluster
eval $KUBECTL_CONFIG_CMD

# Verify cluster access
kubectl get nodes

# You should see output like:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-10-xxx.ec2.internal  Ready    <none>   2m    v1.28.x
# ip-10-0-11-xxx.ec2.internal  Ready    <none>   2m    v1.28.x
```

### Step 6: Verify Kubernetes Resources

```bash
# Check namespaces
kubectl get namespaces

# Check deployments in retail-store namespace
kubectl get deployments -n retail-store

# Check pods
kubectl get pods -n retail-store

# Check services
kubectl get svc -n retail-store

# Check ingress
kubectl get ingress -n retail-store

# View logs for a service
kubectl logs -n retail-store -l app=auth-service --tail=100
```

## Managing the EKS Cluster

### View Cluster Status

```bash
# Get cluster info
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check pod status
kubectl get pods -n retail-store -o wide

# Check resource usage
kubectl top nodes
kubectl top pods -n retail-store
```

### Scaling Services

```bash
# Manual scaling (HPA is also configured for auto-scaling)
kubectl scale deployment auth-service --replicas=3 -n retail-store
kubectl scale deployment product-service --replicas=3 -n retail-store
kubectl scale deployment order-service --replicas=3 -n retail-store
kubectl scale deployment payment-service --replicas=3 -n retail-store
```

### Viewing Logs

```bash
# Stream logs from a specific service
kubectl logs -f -n retail-store -l app=auth-service

# View logs from all pods of a service
kubectl logs -n retail-store -l app=product-service --all-containers=true

# View previous logs (for crashed pods)
kubectl logs -n retail-store <pod-name> --previous
```

### Port Forwarding (for local testing)

```bash
# Forward auth service to local port
kubectl port-forward -n retail-store svc/auth-service 8081:8081

# Forward product service to local port
kubectl port-forward -n retail-store svc/product-service 8082:8082

# You can now access services at localhost:8081, localhost:8082, etc.
```

## Updating Service Deployments

### Method 1: Update Image in Deployment

```bash
# Update image for a service
kubectl set image deployment/auth-service \
  auth-service=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/retail-store-auth-service:v2 \
  -n retail-store

# Check rollout status
kubectl rollout status deployment/auth-service -n retail-store
```

### Method 2: Edit Deployment YAML

```bash
# Edit deployment directly
kubectl edit deployment auth-service -n retail-store

# Make changes to the image or config, save and exit
# Kubernetes will automatically rollout the changes
```

### Method 3: Terraform Update

```bash
# If you modify the image URL in terraform, apply changes
cd aws-infrastructure
terraform plan -out=tfplan
terraform apply tfplan
```

## Monitoring and Logging

### CloudWatch Integration

All EKS cluster logs are automatically sent to CloudWatch:

```bash
# View cluster logs in CloudWatch
aws logs tail /aws/eks/retail-store/cluster --follow
```

### kubectl Monitoring

```bash
# Watch pod status in real-time
kubectl get pods -n retail-store -w

# Get detailed pod information
kubectl describe pod <pod-name> -n retail-store

# Get events
kubectl get events -n retail-store --sort-by='.lastTimestamp'
```

## Cost Optimization

1. **Spot Instances**: Configure node groups to use spot instances
   ```bash
   # Modify node group configuration in variables.tf:
   # variable "node_capacity_type" {
   #   default = "SPOT"  # Use SPOT instead of ON_DEMAND
   # }
   ```

2. **Cluster Autoscaler**: Automatically scale nodes based on pod demand

3. **Resource Limits**: Set resource requests/limits in pods (already configured)

4. **Right-sizing**: Adjust `node_instance_types` based on workload requirements

## Troubleshooting

### Pods Not Starting

```bash
# Check pod description for errors
kubectl describe pod <pod-name> -n retail-store

# Check logs
kubectl logs <pod-name> -n retail-store

# Check events
kubectl get events -n retail-store --sort-by='.lastTimestamp'
```

### Database Connection Issues

```bash
# Verify RDS endpoint
terraform output rds_cluster_endpoint

# Test connectivity from pod
kubectl exec -it <pod-name> -n retail-store -- \
  mysql -h <rds-endpoint> -u admin -p -D retaildb

# Check security group rules
aws ec2 describe-security-groups --filter "Name=group-name,Values=retail-store-rds-sg"
```

### Service Not Accessible

```bash
# Check service status
kubectl describe svc <service-name> -n retail-store

# Check endpoints
kubectl get endpoints -n retail-store

# Test connectivity within cluster
kubectl exec -it <pod-name> -n retail-store -- \
  curl http://auth-service:8081/api/auth
```

## Cleanup and Destruction

To remove all AWS resources:

```bash
cd aws-infrastructure

# Destroy infrastructure
terraform destroy

# Confirm the destruction
```

**Warning**: This will delete:
- EKS cluster
- RDS database (with final snapshot skipped)
- VPC and subnets
- ECR repositories (if empty)
- S3 bucket
- All associated resources

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider EKS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## Support

For issues with:
- **AWS EKS**: Check AWS documentation and CloudWatch logs
- **Kubernetes**: Use `kubectl describe` and `kubectl logs`
- **Terraform**: Review `terraform state` and plan output
- **Application errors**: Check service logs via `kubectl logs`
