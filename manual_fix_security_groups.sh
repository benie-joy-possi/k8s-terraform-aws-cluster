#!/bin/bash

echo "=== Manual Security Group Fix Instructions ==="
echo ""

echo "Since AWS CLI is not configured, here are the manual steps:"
echo ""

echo "1. Open AWS Console in your browser"
echo "   https://console.aws.amazon.com/ec2/"
echo ""

echo "2. Go to EC2 > Instances"
echo ""

echo "3. Find your instances:"
echo "   - Master: ec2-51-20-43-244.eu-north-1.compute.amazonaws.com"
echo "   - Worker-1: ec2-16-170-98-124.eu-north-1.compute.amazonaws.com"
echo "   - Worker-2: ec2-51-21-255-93.eu-north-1.compute.amazonaws.com"
echo ""

echo "4. For EACH instance:"
echo "   a. Select the instance"
echo "   b. Click on the Security Group link (in the Security tab)"
echo "   c. Click 'Edit inbound rules'"
echo "   d. Click 'Add rule'"
echo "   e. Configure the rule:"
echo "      - Type: All traffic"
echo "      - Protocol: All"
echo "      - Port range: All"
echo "      - Source: Custom"
echo "      - Security group: Select the same security group"
echo "   f. Click 'Save rules'"
echo ""

echo "5. Alternative (if the above doesn't work):"
echo "   Add these specific rules:"
echo "   - TCP port 6443 (Kubernetes API)"
echo "   - TCP port 10250 (Kubelet)"
echo "   - TCP port 2379 (etcd client)"
echo "   - TCP port 2380 (etcd peer)"
echo "   - All ICMP (for ping)"
echo ""

echo "6. After fixing security groups, test connectivity:"
echo "   ./test_connectivity.sh"
echo ""

echo "7. If connectivity works, join worker nodes:"
echo "   ./join_worker_nodes.sh"
echo ""

echo "=== Quick Test Commands ==="
echo ""
echo "Test ping from worker to master:"
echo "ssh -i /home/ju-nine/Downloads/gis-openstack-m07-y25-ec2-principal20250729104020211200000003\\(1\\).pem ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com 'ping -c 3 21.32.12.44'"
echo ""
echo "Test port 6443 connectivity:"
echo "ssh -i /home/ju-nine/Downloads/gis-openstack-m07-y25-ec2-principal20250729104020211200000003\\(1\\).pem ubuntu@ec2-16-170-98-124.eu-north-1.compute.amazonaws.com 'timeout 5 bash -c \"</dev/tcp/21.32.12.44/6443\" && echo \"Port 6443 is reachable\" || echo \"Port 6443 is NOT reachable\"'" 