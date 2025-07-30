#!/bin/bash

set -e

KEY_PATH="/home/ju-nine/Downloads/gis-openstack-m07-y25-ec2-principal20250729104020211200000003(1).pem"

echo "=== Joining Worker Nodes to Kubernetes Cluster ==="
echo ""

# Test connectivity first
echo "Testing connectivity to master node..."
if ! ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com "ping -c 1 21.32.12.44" &> /dev/null; then
    echo "❌ Cannot ping master node. Please fix security groups first."
    echo "Run: ./fix_security_groups.sh"
    exit 1
fi

echo "✅ Connectivity test passed!"

# Get the join command from master
echo "Getting join command from master node..."
JOIN_CMD=$(ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "sudo kubeadm token create --print-join-command")

echo "Join command: $JOIN_CMD"
echo ""

# Join worker-1
echo "=== Joining Worker-1 (ec2-16-170-98-124) ==="
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com "sudo $JOIN_CMD --ignore-preflight-errors=all"

if [ $? -eq 0 ]; then
    echo "✅ Worker-1 joined successfully!"
else
    echo "❌ Worker-1 failed to join"
fi

echo ""

# Join worker-2
echo "=== Joining Worker-2 (ec2-51-21-255-93) ==="
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-21-255-93.eu-north-1.compute.amazonaws.com "sudo $JOIN_CMD --ignore-preflight-errors=all"

if [ $? -eq 0 ]; then
    echo "✅ Worker-2 joined successfully!"
else
    echo "❌ Worker-2 failed to join"
fi

echo ""

# Wait a moment for nodes to register
echo "Waiting for nodes to register..."
sleep 10

# Check cluster status
echo "=== Cluster Status ==="
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "kubectl get nodes"

echo ""
echo "=== Cluster Details ==="
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "kubectl get pods --all-namespaces"

echo ""
echo "🎉 Kubernetes cluster setup complete!"
echo ""
echo "To access your cluster from your local machine:"
echo "1. Copy the kubeconfig:"
echo "   scp -i $KEY_PATH ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com:/home/ubuntu/.kube/config ~/.kube/config"
echo ""
echo "2. Install kubectl locally:"
echo "   sudo apt-get install -y kubectl"
echo ""
echo "3. Test your cluster:"
echo "   kubectl get nodes" 