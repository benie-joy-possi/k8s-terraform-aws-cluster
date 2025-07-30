#!/bin/bash

set -e

# Enable debug mode
set -x

# Setup logging
exec > >(tee /var/log/k8s-master-setup.log) 2>&1
echo "=== Kubernetes Master Setup Started at $(date) ==="
echo "🔍 Debug mode enabled - you will see detailed output"
echo "📝 All output is being logged to /var/log/k8s-master-setup.log"

# Function for error handling
error_exit() {
    echo "ERROR: $1" >&2
    echo "Setup failed at $(date)" >> /var/log/k8s-master-setup.log
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

# Configure kubelet to use Docker
echo "Configuring kubelet for Docker..."
mkdir -p /etc/systemd/system/kubelet.service.d
cat > /etc/systemd/system/kubelet.service.d/20-extra-args.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///var/run/dockershim.sock"
EOF

# Enable kubelet
systemctl enable kubelet
echo "Step 5 completed successfully!"

echo "Step 5: Initializing Kubernetes cluster..."
# Reset any existing cluster first
echo "Resetting any existing cluster..."
kubeadm reset --force || true

# Initialize cluster with simplified configuration and verbose output
echo "Starting kubeadm init with verbose output..."
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) \
  --v=5

# Check if kubeadm init was successful
if [ $? -eq 0 ]; then
    echo "kubeadm init completed successfully!"
else
    echo "kubeadm init failed."
    error_exit "Failed to initialize Kubernetes cluster"
fi

echo "Step 6: Configuring kubectl..."
mkdir -p /home/ubuntu/.kube
cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
echo "Step 7 completed successfully!"

echo "Step 7: Creating join command..."
# Create join command for workers
kubeadm token create --print-join-command > /home/ubuntu/join-command.sh
chmod +x /home/ubuntu/join-command.sh
chown ubuntu:ubuntu /home/ubuntu/join-command.sh
echo "Step 8 completed successfully!"

echo "Step 8: Installing Flannel CNI..."
# Install Flannel network plugin
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml || error_exit "Failed to install Flannel"
echo "Step 9 completed successfully!"

echo "Step 9: Verifying cluster status..."
# Wait for nodes to be ready
sleep 30
kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes || error_exit "Failed to get node status"
echo "Step 10 completed successfully!"

echo "=== Kubernetes Master Setup Completed Successfully at $(date) ==="
echo "Cluster join command saved to: /home/ubuntu/join-command.sh"
echo "Kubeconfig available at: /home/ubuntu/.kube/config"