#!/bin/bash

set -e

KEY_PATH="/home/ju-nine/Downloads/gis-openstack-m07-y25-ec2-principal20250729104020211200000003(1).pem"
MASTER_IP="21.32.12.44"
WORKER1_DNS="ec2-16-170-98-124.eu-north-1.compute.amazonaws.com"

echo "=== Testing for Zero Packet Loss ==="
echo ""

echo "🔍 Testing ping connectivity..."
PING_RESULT=$(ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@$WORKER1_DNS "ping -c 10 $MASTER_IP" 2>/dev/null | grep "packet loss" || echo "100% packet loss")

echo "Ping result: $PING_RESULT"

if echo "$PING_RESULT" | grep -q "0% packet loss"; then
    echo "✅ ZERO PACKET LOSS ACHIEVED!"
    echo ""
    echo "🔍 Testing port 6443 connectivity..."
    PORT_RESULT=$(ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@$WORKER1_DNS "timeout 5 bash -c '</dev/tcp/$MASTER_IP/6443' && echo '✅ Port 6443 reachable' || echo '❌ Port 6443 blocked'" 2>/dev/null || echo "❌ Port test failed")
    echo "Port result: $PORT_RESULT"
    
    if echo "$PORT_RESULT" | grep -q "✅ Port 6443 reachable"; then
        echo ""
        echo "🎉 PERFECT! Ready to join worker nodes!"
        echo ""
        echo "Getting join command..."
        JOIN_CMD=$(ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "sudo kubeadm token create --print-join-command")
        echo "Join command: $JOIN_CMD"
        echo ""
        echo "Now you can join worker nodes with:"
        echo "ssh -i $KEY_PATH ubuntu@$WORKER1_DNS 'sudo $JOIN_CMD --ignore-preflight-errors=all'"
    else
        echo "❌ Port 6443 still blocked - check security groups for port 6443"
    fi
else
    echo "❌ Still have packet loss - fix security groups first"
    echo ""
    echo "📋 Follow the instructions in FINAL_SECURITY_GROUP_FIX.md"
    echo "🔗 AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=eu-north-1#Instances:sort=instanceId"
fi

echo ""
echo "=== Current Cluster Status ==="
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-51-20-43-244.eu-north-1.compute.amazonaws.com "kubectl get nodes" 2>/dev/null || echo "Cannot get cluster status" 