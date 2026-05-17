#!/bin/bash
set -e

### Disable swap ###
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

### Kernel modules ###
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

### Sysctl settings ###
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

### Install containerd ###
apt update
apt install -y containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

### Kubernetes repo ###
apt-get install -y apt-transport-https ca-certificates curl

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
| gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
| tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

### Set hostname ###
hostnamectl set-hostname k8s-master

### Initialize cluster ###
kubeadm init --pod-network-cidr=192.168.0.0/16

### kubeconfig setup ###
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

### Install Calico network ###
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

### Show status ###
kubectl get nodes
kubectl get pods -n kube-system

echo "MASTER SETUP COMPLETE"
