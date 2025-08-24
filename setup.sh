#!/bin/bash

set -e

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting Docker installation and vLLM setup..."

if command_exists docker; then
    echo "Docker is already installed"
else
    echo "Installing Docker..."
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    export DEBIAN_FRONTEND=noninteractive
    echo "deb http://security.ubuntu.com/ubuntu $(lsb_release -cs)-security main restricted universe multiverse" > /etc/apt/sources.list
    echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -cs) main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -cs)-updates main restricted universe multiverse" >> /etc/apt/sources.list
    apt-get update -o Acquire::AllowInsecureRepositories=true || true
    apt-get install -y ubuntu-keyring
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 871920D1991BC93C
    apt-get update || { echo "APT update failed, retrying..."; sleep 5; apt-get update; }
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker azureuser || echo "Failed to add user to docker group, continuing..."
    echo "Docker installed successfully"
fi

systemctl enable docker
systemctl start docker

export HF_TOKEN=""
export INFERENCE_MODEL="TinyLlama/TinyLlama-1.1B-Chat-v1.0"
DOCKER_IMAGE="public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.9.2"

echo "Starting vLLM inference endpoint..."
echo "Using model: $INFERENCE_MODEL"
echo "Using Docker image: $DOCKER_IMAGE"

# Run Docker container in detached mode and capture container ID
docker run -d \
    --pull always \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    --env "HUGGING_FACE_HUB_TOKEN=$HF_TOKEN" \
    -p 8080:8080 \
    --ipc=host \
    --name vllm_container \
    $DOCKER_IMAGE \
    --model $INFERENCE_MODEL \
    --max-model-len 2048 > /var/log/vllm_start.log 2>&1 || { echo "Docker run failed, check /var/log/vllm_start.log"; cat /var/log/vllm_start.log; exit 1; }

# Wait for container to start and verify it's running
sleep 10
CONTAINER_ID=$(docker ps -q -f name=vllm_container)
if [ -n "$CONTAINER_ID" ]; then
    echo "vLLM container started: $CONTAINER_ID"
    docker logs $CONTAINER_ID >> /var/log/vllm_start.log 2>&1
    # Verify the vLLM endpoint is responsive
    if curl --fail http://localhost:8080/health > /dev/null 2>&1; then
        echo "vLLM endpoint is healthy"
        exit 0  # Exit successfully to signal completion
    else
        echo "vLLM endpoint is not responding"
        docker logs $CONTAINER_ID >> /var/log/vllm_start.log 2>&1
        exit 1
    fi
else
    echo "vLLM container failed to start, check logs"
    cat /var/log/vllm_start.log
    exit 1
fi
