# MERN Hello World with Kubernetes Horizontal Pod Autoscaler (HPA)

This project demonstrates how to implement and test Horizontal Pod Autoscaler (HPA) in a Kubernetes cluster using a simple MERN (MongoDB, Express, React, Node.js) application. The application includes CPU-intensive endpoints that can be used to test the HPA functionality.

## Prerequisites

- Docker installed and configured
- Kubernetes cluster (Minikube, Docker Desktop, or a cloud-based Kubernetes service)
- kubectl CLI tool installed and configured
- Node.js and npm installed (for local development and testing)

## Project Structure

- `index.js`: Main application file with CPU-intensive endpoints
- `Dockerfile`: Docker configuration for building the application image
- `deployment.yaml`: Kubernetes deployment configuration
- `mern-deployment.yaml`: Updated deployment configuration with resource limits for HPA
- `service.yaml`: Kubernetes service configuration for exposing the application
- `hpa.yaml`: Horizontal Pod Autoscaler configuration
- `loadtest.js`: Load testing script using the loadtest npm package
- `test-hpa-loadtest.sh`: Shell script for testing HPA functionality

## Setup and Deployment

### 1. Install Metrics Server (required for HPA)

The Metrics Server is required for HPA to collect CPU and memory metrics from pods:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Verify that the Metrics Server is running:

```bash
kubectl get deployment metrics-server -n kube-system
```

### 2. Build and Push the Docker Image

```bash
# Build the Docker image
docker build -t <your-docker-username>/hello-world:hpa .

# Push the image to Docker Hub
docker push <your-docker-username>/hello-world:hpa
```

### 3. Deploy the Application to Kubernetes

```bash
# Apply the deployment with resource limits
kubectl apply -f mern-deployment.yaml

# Apply the service configuration
kubectl apply -f service.yaml

# Apply the HPA configuration
kubectl apply -f hpa.yaml
```

### 4. Verify the Deployment

```bash
# Check if the pods are running
kubectl get pods

# Check if the service is properly configured
kubectl get svc

# Check the initial state of the HPA
kubectl get hpa mern-hello-world-hpa
```

## Testing the HPA Functionality

### Method 1: Using the Interactive Test Script

The project includes an interactive shell script for testing HPA functionality:

```bash
# Make the script executable
chmod +x test-hpa-loadtest.sh

# Run the script
./test-hpa-loadtest.sh
```

The script provides the following options:
- Apply Kubernetes configurations
- Check HPA status
- Run light load test (CPU-intensive)
- Run heavy load test (Prime numbers)
- Run custom load test
- Monitor HPA
- Monitor pods
- View detailed HPA description

### Method 2: Manual Testing with Direct Commands

#### 1. Monitor the HPA and Pods

Open two terminal windows to monitor the HPA and pods:

```bash
# Terminal 1: Monitor HPA
kubectl get hpa mern-hello-world-hpa -w

# Terminal 2: Monitor pods
kubectl get pods -w
```

#### 2. Port Forward to Access the Application

```bash
# Port forward to the service
kubectl port-forward service/mern-hello-world-service 3000:80

# Or port forward directly to a pod
kubectl port-forward pod/<pod-name> 3001:3000
```

#### 3. Generate CPU Load

You can use the following methods to generate CPU load:

**a. Using curl commands:**

```bash
# Generate load with Fibonacci calculations
for i in {1..20}; do curl "http://localhost:3001/cpu-intensive?iterations=42" & done

# Generate heavier load with prime number calculations
for i in {1..10}; do curl "http://localhost:3001/heavy-load?limit=1000000" & done
```

**b. Using the loadtest npm package:**

```bash
# Install dependencies
npm install

# Run a load test against the CPU-intensive endpoint
node loadtest.js --endpoint cpu-intensive --concurrency 15 --requests 1000 --rps 30 --param 45

# Run a load test against the heavy-load endpoint
node loadtest.js --endpoint heavy-load --concurrency 5 --requests 100 --rps 10 --param 500000
```

### 3. Observe the HPA in Action

As the CPU utilization increases above 80%, you should observe:
1. The HPA will increase the number of replicas
2. New pods will be created automatically
3. The load will be distributed across the pods

You can verify this by watching the HPA status and pods in the monitoring terminals.

## Available Endpoints

The application provides the following endpoints:

- `/`: Basic "Hello World" endpoint
- `/cpu-intensive`: CPU-intensive endpoint that calculates Fibonacci numbers
  - Query parameter: `iterations` (default: 40)
- `/heavy-load`: Even more CPU-intensive endpoint that finds prime numbers
  - Query parameter: `limit` (default: 100000)
- `/health`: Health check endpoint that returns the pod name and timestamp
- `/metrics`: CPU load monitoring endpoint that returns memory usage statistics

## Troubleshooting

### 1. HPA Shows `<unknown>` for CPU Utilization

This usually indicates that the Metrics Server is not installed or not functioning properly. Verify that the Metrics Server is running:

```bash
kubectl get deployment metrics-server -n kube-system
```

### 2. Connection Refused When Accessing the Application

This could be due to several reasons:
- The service is not properly configured
- The pods are not running correctly
- Port forwarding is not set up correctly

Try port forwarding directly to a pod to isolate the issue:

```bash
kubectl port-forward pod/<pod-name> 3001:3000
```

### 3. Pods Not Scaling Despite High CPU Load

- Check if the HPA is configured correctly
- Verify that the pods have resource requests and limits set
- Ensure that the Metrics Server is collecting data properly
- The HPA may need some time to collect enough metrics before scaling

## Additional Resources

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Metrics Server GitHub Repository](https://github.com/kubernetes-sigs/metrics-server)
- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
