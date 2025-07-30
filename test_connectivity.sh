#!/bin/bash

KEY_PATH="/home/ju-nine/Downloads/gis-openstack-m07-y25-ec2-principal20250729104020211200000003(1).pem"

echo "=== Testing Connectivity Between Instances ==="
echo ""

echo "Testing ping from worker-1 to master..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com "ping -c 3 21.32.12.44"

echo ""
echo "Testing ping from master to worker-1..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "ping -c 3 21.32.15.122"

echo ""
echo "Testing port 6443 connectivity from worker-1 to master..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com "timeout 5 bash -c '</dev/tcp/21.32.12.44/6443' && echo 'Port 6443 is reachable' || echo 'Port 6443 is NOT reachable'"

echo ""
echo "=== Current Cluster Status ==="
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "kubectl get nodes"

echo ""
echo "=== If connectivity is working, you can join worker nodes ==="
echo "Join command:"
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "sudo kubeadm token create --print-join-command" 