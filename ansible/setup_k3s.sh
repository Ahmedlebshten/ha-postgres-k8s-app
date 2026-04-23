#!/bin/bash
set -e

echo "Updating apt cache..."
sudo apt-get update -y

echo "Installing required dependencies..."
sudo apt-get install -y curl ca-certificates

echo "Installing K3s using official script..."
curl -sfL https://get.k3s.io | sh -

echo "Setting permissions for k3s.yaml..."
sudo chmod 0644 /etc/rancher/k3s/k3s.yaml

echo "Creating .kube directory for ubuntu user..."
sudo mkdir -p /home/ubuntu/.kube
sudo chown ubuntu:ubuntu /home/ubuntu/.kube
sudo chmod 0755 /home/ubuntu/.kube

echo "Copying config to ubuntu user..."
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo chmod 0600 /home/ubuntu/.kube/config

echo "Exporting KUBECONFIG permanently..."
if ! grep -q "export KUBECONFIG=~/.kube/config" /home/ubuntu/.bashrc; then
  echo "export KUBECONFIG=~/.kube/config" >> /home/ubuntu/.bashrc
fi

echo "K3s installation and setup complete!"
