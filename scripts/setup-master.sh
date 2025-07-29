#!/bin/bash

set -e

# install packages
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

sudo apt-get update
sudo apt-get install -y docker.io kubelet kubeadm kubectl
sudo systemctl enable docker && sudo systemctl start docker
sudo systemctl enable kubelet

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 > /home/ec2-user/init.log

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown ec2-user:ec2-user $HOME/.kube/config

# Save join command
kubeadm token create --print-join-command > /home/ec2-user/join-command.sh
chmod +x /home/ec2-user/join-command.sh

# Install Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml