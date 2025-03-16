# Demo with Kubernetes Horizontal Pod Autoscaler (HPA) using Kind

This project demonstrates how to implement and test Horizontal Pod Autoscaler (HPA) in a Kubernetes cluster using Kind (Kubernetes IN Docker) with a simple application. The application includes CPU-intensive endpoints that can be used to test the HPA functionality.

## Prerequisites

- Docker installed and configured
- Node.js and npm installed (for local development and testing)

## Step-by-Step Guide for Beginners

### 1. Create a Kind Cluster

You can create a Kind cluster with a single command:

```bash
# Create a default Kind cluster
kind create cluster --name hpa-test

# Check if the cluster is running
kubectl cluster-info
kubectl get nodes
```

### 2. Install Metrics Server (required for HPA)

The Metrics Server is required for HPA to collect CPU and memory metrics from pods:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

kubectl wait --for=condition=Available deployment/metrics-server -n kube-system --timeout=300s

kubectl get deployment metrics-server -n kube-system
```

### 3. Build and Load the Docker Image into Kind

```bash
# Build the Docker image
docker build -t hello-world:hpa .

docker tag hello-world jyotiprakashh/hello-world

docker push jyotiprakashh/hello-world
```

### 4. Deploy the Application to Kubernetes

```bash
# Apply the deployment with resource limits
kubectl apply -f deployment.yaml

# Apply the service configuration
kubectl apply -f service.yaml

# Apply the HPA configuration
kubectl apply -f hpa.yaml

```

### 5. Verify the Deployment

```bash
# Check if the pods are running
kubectl get pods

kubectl get svc

kubectl get hpa demo-hpa
```

### 6. Set Up Port Forwarding to Access the Application

```bash
# Use port-forwarding
kubectl port-forward service/demo-service 8080:80
# Access the service at http://localhost:8080
```

### 7. Monitor HPA and Pods

Open two terminal windows to monitor the HPA and pods:

```bash
# Terminal 1: Monitor HPA
kubectl get hpa demo-hpa -w

# Terminal 2: Monitor pods
kubectl get pods -w
```

#### Run Load Tests with loadtest npm package

First, install the loadtest npm package if you haven't already:

```bash
# Install loadtest globally
npm install -g loadtest
```

Now you can run load tests against the CPU-intensive endpoints to trigger the HPA using the loadtest command-line tool:

```bash
# Run a light load test against the CPU-intensive endpoint
# This sends 500 requests with 10 concurrent clients at 20 requests per second
loadtest -c 10 -n 500 --rps 20 http://localhost:8080/cpu-intensive?iterations=42

# Run a heavy load test against the heavy-load endpoint
# This sends 100 requests with 5 concurrent clients at 10 requests per second
loadtest -c 5 -n 100 --rps 10 http://localhost:8080/heavy-load?limit=500000
```

### 8. Observe HPA in Action

While the load tests are running, observe the HPA and pods in your monitoring terminals:

```bash
# Check HPA status
kubectl get hpa demo-hpa

# Get detailed information about the HPA
kubectl describe hpa demo-hpa
```

You should see:
1. The CPU utilization increasing above 80%
2. The HPA increasing the number of replicas
3. New pods being created automatically
4. The load being distributed across the pods

### 9. Visualize the Results

You can use the metrics endpoint to see the CPU load on individual pods:

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -l app=demo -o jsonpath='{.items[0].metadata.name}')

# Port forward to the pod
kubectl port-forward $POD_NAME 8081:3000

# Access the metrics endpoint
curl http://localhost:8081/metrics
```

### 10. Clean Up

When you're done testing, you can clean up your Kind cluster:

```bash
# Delete the Kind cluster
kind delete cluster --name hpa-test