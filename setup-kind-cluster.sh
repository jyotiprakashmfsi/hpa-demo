#!/bin/bash

echo "Setting up Kind Kubernetes Cluster for HPA Demo"
echo "=============================================="

# Check if Kind is installed
if ! command -v kind &> /dev/null; then
    echo "Kind is not installed. Installing Kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
fi

# Create Kind cluster
echo "Creating Kind cluster with config..."
kind create cluster --config kind-config.yaml

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install metrics server (required for HPA)
echo "Installing metrics server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics server to work with Kind (skip TLS verification)
echo "Patching metrics server to work with Kind..."
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Wait for metrics server to be ready
echo "Waiting for metrics server to be ready..."
kubectl wait --for=condition=Available deployment/metrics-server -n kube-system --timeout=300s

echo "Building Docker image..."
docker build -t hello-world:hpa .

echo "Loading Docker image into Kind cluster..."
kind load docker-image hello-world:hpa --name hpa-demo

echo "Applying Kubernetes configurations..."
kubectl apply -f mern-deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/mern-hello-world-hpa

echo "Setup complete! Your Kind cluster is ready for HPA testing."
echo "Current HPA status:"
kubectl get hpa mern-hello-world-hpa

echo ""
echo "To run load tests, use: ./test-hpa-loadtest.sh"
