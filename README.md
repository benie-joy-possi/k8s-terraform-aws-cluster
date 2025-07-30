# Kubernetes Cluster Setup on AWS with Terraform

This project automates the deployment of a production-ready Kubernetes cluster on AWS using Terraform. It creates a 3-node cluster (1 master + 2 workers) with proper networking, security groups, and automated setup scripts.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Master Node   │    │   Worker Node   │    │   Worker Node   │
│   (Control      │    │       1         │    │       2         │
│    Plane)       │    │                 │    │                 │
│                 │    │                 │    │                 │
│ • kube-apiserver│    │ • Application   │    │ • Application   │
│ • etcd          │    │   Pods          │    │   Pods          │
│ • scheduler     │    │ • Auto-scaling  │    │ • Load balancing│
│ • controller    │    │ • Networking    │    │ • Networking    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (version >= 1.0)
- SSH key pair for EC2 instance access
- kubectl installed locally

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd k8s-terraform-aws-cluster
```

### 2. Configure Your Environment
```bash
# Copy the example configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the configuration with your values
nano terraform/terraform.tfvars
```

### 3. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Setup Kubernetes Cluster
```bash
# The Terraform configuration will automatically:
# - Install Docker and Kubernetes on all nodes
# - Initialize the master node
# - Join worker nodes to the cluster
```

### 5. Verify Cluster
```bash
# Copy example scripts and update with your values
cp scripts/test_connectivity.sh.example scripts/test_connectivity.sh
cp scripts/join_worker_nodes.sh.example scripts/join_worker_nodes.sh

# Test connectivity
./scripts/test_connectivity.sh

# Check cluster status
ssh -i /path/to/your/key.pem ubuntu@master-dns "kubectl get nodes"
```

## 📁 Project Structure

```
k8s-terraform-aws-cluster/
├── terraform/
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Variable definitions
│   ├── terraform.tfvars.example # Example configuration
│   └── .gitignore             # Terraform-specific ignores
├── scripts/
│   ├── setup_master.sh        # Master node setup script
│   ├── setup_worker.sh        # Worker node setup script
│   ├── test_connectivity.sh.example # Example connectivity test
│   └── join_worker_nodes.sh.example # Example join script
├── index.html                 # Project presentation
├── README.md                  # This file
└── .gitignore                # Global gitignore
```

## 🔧 Configuration

### terraform.tfvars
Update the `terraform/terraform.tfvars` file with your specific values:

```hcl
region = "eu-north-1"  # Your preferred AWS region

instances = {
  master = {
    dns = "ec2-XX-XX-XX-XX.eu-north-1.compute.amazonaws.com"
    ip  = "XX.XX.XX.XX"
    kp  = "/path/to/your/private-key.pem"
  }
  worker-1 = {
    dns = "ec2-XX-XX-XX-XX.eu-north-1.compute.amazonaws.com"
    ip  = "XX.XX.XX.XX"
    kp  = "/path/to/your/private-key.pem"
  }
  worker-2 = {
    dns = "ec2-XX-XX-XX-XX.eu-north-1.compute.amazonaws.com"
    ip  = "XX.XX.XX.XX"
    kp  = "/path/to/your/private-key.pem"
  }
}
```

## 🔒 Security Features

- **Security Groups**: Configured for Kubernetes communication
- **SSH Key Authentication**: Secure access to instances
- **Private Subnets**: Isolated networking
- **IAM Roles**: Least privilege access
- **Network Policies**: Pod-to-pod communication control

## 🛠️ Troubleshooting

### Common Issues

1. **Security Group Issues**
   - Ensure ports 6443, 10250, and ICMP are open
   - Check security group rules for internal communication

2. **Kubernetes Init Fails**
   - Verify instance has sufficient resources
   - Check Docker installation
   - Review kubelet logs

3. **Worker Join Fails**
   - Ensure master node is fully initialized
   - Check network connectivity
   - Verify join command is correct

### Debug Commands

```bash
# Check EC2 instances
aws ec2 describe-instances

# Check security groups
aws ec2 describe-security-groups

# Check kubelet logs
ssh -i /path/to/key.pem ubuntu@master-ip "journalctl -u kubelet -f"

# Check cluster status
ssh -i /path/to/key.pem ubuntu@master-ip "kubectl get nodes"
ssh -i /path/to/key.pem ubuntu@master-ip "kubectl get pods --all-namespaces"
```

## 📚 Learning Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Best Practices](https://aws.amazon.com/eks/resources/best-practices/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Security Notice

- **Never commit private keys or sensitive data**
- **Use environment variables for credentials**
- **Regularly rotate access keys**
- **Monitor AWS CloudTrail logs**
- **Keep Terraform state files secure**

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS and Kubernetes documentation
3. Open an issue in the repository

---

**Team**: Joy, Ju-nine, Usher, Emmanuel  
**Project**: AWS Kubernetes Cluster with Terraform  
**Version**: 1.0.0 