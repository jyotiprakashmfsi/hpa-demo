#!/bin/bash

echo "HPA Load Testing Script for Kind Cluster"
echo "========================================"

# Check if loadtest and yargs are installed
if ! npm list -g loadtest &> /dev/null; then
  echo "Installing loadtest globally..."
  npm install -g loadtest
fi

if ! npm list yargs &> /dev/null; then
  echo "Installing yargs locally..."
  npm install yargs
fi

# Function to monitor HPA status
function monitor_hpa() {
  echo "Monitoring HPA status..."
  kubectl get hpa mern-hello-world-hpa -w
}

# Function to monitor pods
function monitor_pods() {
  echo "Monitoring pods..."
  kubectl get pods -w
}

# Function to run loadtest with specified parameters
function run_loadtest() {
  local endpoint=$1
  local concurrency=$2
  local requests=$3
  local rps=$4
  local param=$5
  
  echo "Running loadtest against /$endpoint endpoint"
  echo "Concurrency: $concurrency, Requests: $requests, RPS: $rps, Param: $param"
  
  # Get the NodePort of the service
  local NODE_PORT=$(kubectl get svc mern-hello-world-service -o jsonpath='{.spec.ports[0].nodePort}')
  
  # Get the IP of the Kind node
  local KIND_IP="localhost"
  
  echo "Service is available at: http://$KIND_IP:$NODE_PORT"
  
  node loadtest.js --endpoint $endpoint --concurrency $concurrency --requests $requests --rps $rps --param $param --host $KIND_IP --port $NODE_PORT
}

# Function to apply Kubernetes configurations
function apply_k8s_configs() {
  echo "Applying Kubernetes configurations..."
  kubectl apply -f mern-deployment.yaml
  kubectl apply -f service.yaml
  kubectl apply -f hpa.yaml
  
  echo "Waiting for deployment to be ready..."
  kubectl rollout status deployment/mern-hello-world-hpa
  
  echo "Current HPA status:"
  kubectl get hpa mern-hello-world-hpa
}

# Function to display Kind cluster info
function kind_cluster_info() {
  echo "Kind Cluster Information:"
  echo "========================="
  echo "Cluster Nodes:"
  kubectl get nodes
  echo -e "\nCluster Pods:"
  kubectl get pods -A
  echo -e "\nCluster Services:"
  kubectl get svc -A
}

# Function to port-forward the service
function port_forward_service() {
  local local_port=$1
  echo "Port forwarding service to localhost:$local_port..."
  kubectl port-forward service/mern-hello-world-service $local_port:80
}

# Main menu
PS3="Select an option: "
options=(
  "Apply Kubernetes Configurations" 
  "Check HPA Status" 
  "Run Light Load Test (CPU-Intensive)" 
  "Run Heavy Load Test (Prime Numbers)" 
  "Run Custom Load Test" 
  "Monitor HPA" 
  "Monitor Pods"
  "View Detailed HPA Description"
  "View Kind Cluster Info"
  "Port Forward Service"
  "Exit"
)

select opt in "${options[@]}"
do
  case $opt in
    "Apply Kubernetes Configurations")
      apply_k8s_configs
      ;;
    "Check HPA Status")
      echo "Current HPA status:"
      kubectl get hpa mern-hello-world-hpa
      echo -e "\nCurrent pods:"
      kubectl get pods
      ;;
    "Run Light Load Test (CPU-Intensive)")
      run_loadtest "cpu-intensive" 10 500 20 42
      ;;
    "Run Heavy Load Test (Prime Numbers)")
      run_loadtest "heavy-load" 5 100 10 500000
      ;;
    "Run Custom Load Test")
      read -p "Enter endpoint (cpu-intensive, heavy-load, health): " endpoint
      endpoint=${endpoint:-cpu-intensive}
      
      read -p "Enter concurrency (default: 10): " concurrency
      concurrency=${concurrency:-10}
      
      read -p "Enter number of requests (default: 500): " requests
      requests=${requests:-500}
      
      read -p "Enter requests per second (default: 20): " rps
      rps=${rps:-20}
      
      read -p "Enter parameter value (default: 40): " param
      param=${param:-40}
      
      run_loadtest "$endpoint" "$concurrency" "$requests" "$rps" "$param"
      ;;
    "Monitor HPA")
      monitor_hpa
      ;;
    "Monitor Pods")
      monitor_pods
      ;;
    "View Detailed HPA Description")
      kubectl describe hpa mern-hello-world-hpa
      ;;
    "View Kind Cluster Info")
      kind_cluster_info
      ;;
    "Port Forward Service")
      read -p "Enter local port (default: 8080): " local_port
      local_port=${local_port:-8080}
      port_forward_service $local_port
      ;;
    "Exit")
      echo "Exiting..."
      break
      ;;
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done
