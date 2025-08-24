#!/bin/bash

# Exit on any error
set -e

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting Docker installation and vLLM setup..."

# Check if Docker is already installed
if command_exists docker; then
    echo "Docker is already installed"
else
    echo "Installing Docker..."
    
    # Update package index
    sudo apt-get update
    
    # Install required packages
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
        
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt-get update
    
    # Install Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group (to run docker without sudo)
    sudo usermod -aG docker $USER
    
    echo "Docker installed successfully"
fi

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Set Hugging Face token and model name
export HF_TOKEN=""
export INFERENCE_MODEL="TinyLlama/TinyLlama-1.1B-Chat-v1.0"

# Docker image to use
DOCKER_IMAGE="public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.9.2"

echo "Starting vLLM inference endpoint..."
echo "Using model: $INFERENCE_MODEL"
echo "Using Docker image: $DOCKER_IMAGE"

# Run the Docker container
docker run \
    --pull always \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    --env "HUGGING_FACE_HUB_TOKEN=$HF_TOKEN" \
    -p 8080:8080 \
    --ipc=host \
    $DOCKER_IMAGE \
    --model $INFERENCE_MODEL \
    --max-model-len 32768
