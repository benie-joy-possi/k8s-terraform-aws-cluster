#!/bin/bash

set -e

echo "=== Fixing Security Groups for Kubernetes Cluster ==="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first:"
    echo "sudo apt-get install awscli"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS credentials not configured. Please run:"
    echo "aws configure"
    exit 1
fi

echo "Getting instance information..."

# Get instance IDs and security groups
MASTER_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=dns-name,Values=ec2-51-20-43-244.eu-north-1.compute.amazonaws.com" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

WORKER1_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=dns-name,Values=ec2-16-170-98-124.eu-north-1.compute.amazonaws.com" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

WORKER2_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=dns-name,Values=ec2-51-21-255-93.eu-north-1.compute.amazonaws.com" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

echo "Master Instance ID: $MASTER_INSTANCE_ID"
echo "Worker-1 Instance ID: $WORKER1_INSTANCE_ID"
echo "Worker-2 Instance ID: $WORKER2_INSTANCE_ID"

# Get security group IDs
MASTER_SG=$(aws ec2 describe-instances \
    --instance-ids $MASTER_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

WORKER1_SG=$(aws ec2 describe-instances \
    --instance-ids $WORKER1_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

WORKER2_SG=$(aws ec2 describe-instances \
    --instance-ids $WORKER2_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

echo ""
echo "Security Groups:"
echo "Master SG: $MASTER_SG"
echo "Worker-1 SG: $WORKER1_SG"
echo "Worker-2 SG: $WORKER2_SG"

# Create a list of unique security groups
SGS=($MASTER_SG $WORKER1_SG $WORKER2_SG)
UNIQUE_SGS=($(printf "%s\n" "${SGS[@]}" | sort -u))

echo ""
echo "Unique Security Groups to fix: ${UNIQUE_SGS[@]}"

# Fix each security group
for SG in "${UNIQUE_SGS[@]}"; do
    echo ""
    echo "=== Fixing Security Group: $SG ==="
    
    # Add rule to allow all traffic from the same security group
    echo "Adding rule to allow all traffic from same security group..."
    aws ec2 authorize-security-group-ingress \
        --group-id $SG \
        --protocol all \
        --port -1 \
        --source-group $SG \
        --description "Allow all traffic from same security group for Kubernetes" || echo "Rule might already exist"
    
    # Add specific Kubernetes ports
    echo "Adding Kubernetes API server port (6443)..."
    aws ec2 authorize-security-group-ingress \
        --group-id $SG \
        --protocol tcp \
        --port 6443 \
        --source-group $SG \
        --description "Kubernetes API server" || echo "Rule might already exist"
    
    echo "Adding kubelet port (10250)..."
    aws ec2 authorize-security-group-ingress \
        --group-id $SG \
        --protocol tcp \
        --port 10250 \
        --source-group $SG \
        --description "Kubelet API" || echo "Rule might already exist"
    
    echo "Adding etcd ports..."
    aws ec2 authorize-security-group-ingress \
        --group-id $SG \
        --protocol tcp \
        --port 2379 \
        --source-group $SG \
        --description "etcd client" || echo "Rule might already exist"
    
    aws ec2 authorize-security-group-ingress \
        --group-id $SG \
        --protocol tcp \
        --port 2380 \
        --source-group $SG \
        --description "etcd peer" || echo "Rule might already exist"
    
    echo "Security Group $SG fixed!"
done

echo ""
echo "=== Security Groups Fixed! ==="
echo ""
echo "Now testing connectivity..."

# Test connectivity
KEY_PATH="/home/ju-nine/Downloads/gis-openstack-m07-y25-ec2-principal20250729104020211200000003(1).pem"

echo "Testing ping from worker-1 to master..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com "ping -c 3 21.32.12.44"

echo ""
echo "Testing port 6443 connectivity..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com "timeout 5 bash -c '</dev/tcp/21.32.12.44/6443' && echo '✅ Port 6443 is reachable' || echo '❌ Port 6443 is NOT reachable'"

echo ""
echo "=== If connectivity is working, you can now join worker nodes ==="
echo "Run: ./join_worker_nodes.sh" 