#!/bin/bash

# Deploy script for running Docker container
set -e

DOCKERHUB_USER="gopinathsiva2605"
CONTAINER_NAME="devops-app"

echo "===== Deploying Application ====="

# Stop and remove existing container if running
if [ $(docker ps -q -f name=${CONTAINER_NAME}) ]; then
    echo "Stopping existing container..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi

# Pull latest image
echo "Pulling latest image..."
docker pull ${DOCKERHUB_USER}/dev:latest

# Run new container
echo "Starting new container..."
docker run -d \
    --name ${CONTAINER_NAME} \
    --restart always \
    -p 80:80 \
    ${DOCKERHUB_USER}/dev:latest

echo "===== Deployment Complete ====="
echo "App running at: http://$(curl -s ifconfig.me):80"
