#!/bin/bash

set -e

# Enable debug mode
set -x

# Setup logging
exec > >(tee /var/log/k8s-worker-setup.log) 2>&1
echo "=== Kubernetes Worker Setup Started at $(date) ==="
echo "🔍 Debug mode enabled - you will see detailed output"
echo "📝 All output is being logged to /var/log/k8s-worker-setup.log"

# Function for error handling
error_exit() {
    echo "ERROR: $1" >&2
    echo "Setup failed at $(date)" >> /var/log/k8s-worker-setup.log
    exit 1
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root or with sudo"
fi

echo "Step 1: Updating system packages..."
echo "Running apt-get update..."
apt-get update || error_exit "Failed to update package list"
echo "Installing basic packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || error_exit "Failed to install basic packages"
echo "Step 1 completed successfully!"

echo "Step 2: Installing Docker and Kubernetes..."
echo "Installing Docker and Kubernetes packages..."
# Remove conflicting containerd.io package first
apt-get remove -y containerd.io || true
DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io kubelet kubeadm kubectl || error_exit "Failed to install Docker and Kubernetes"
echo "Step 2 completed successfully!"

echo "Step 3: Configuring Docker..."
# Enable and start Docker
systemctl enable docker && systemctl start docker || error_exit "Failed to start Docker"

# Configure Docker for Kubernetes
echo "Configuring Docker for Kubernetes..."
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl daemon-reload
systemctl restart docker

# Verify Docker is running
if ! systemctl is-active --quiet docker; then
    echo "Docker failed to start, checking logs..."
    systemctl status docker.service
    journalctl -xeu docker.service --no-pager
    error_exit "Failed to start Docker"
fi

echo "Step 3 completed successfully!"

echo "Step 4: Configuring system..."
# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Configure bridge networking
echo "Configuring bridge networking..."
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Configure kubelet to use Docker
echo "Configuring kubelet for Docker..."
mkdir -p /etc/systemd/system/kubelet.service.d
cat > /etc/systemd/system/kubelet.service.d/20-extra-args.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///var/run/dockershim.sock --container-runtime=docker"
EOF

# Also configure kubelet config file
mkdir -p /var/lib/kubelet
cat > /var/lib/kubelet/config.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
containerRuntimeEndpoint: unix:///var/run/dockershim.sock
EOF



# Enable kubelet
systemctl enable kubelet
systemctl daemon-reload
echo "Step 5 completed successfully!"

echo "Step 5: Waiting for join command..."
# The join command will be executed by Terraform after this script completes
echo "Worker setup completed. Ready to join cluster."
echo "=== Kubernetes Worker Setup Completed Successfully at $(date) ==="