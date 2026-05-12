#!/bin/bash
set -e

DOCKERHUB_USER="gopinathsiva2605"
CONTAINER_NAME="devops-app"

echo "===== Deploying Application ====="

# Stop container if running
if [ $(docker ps -q -f name=${CONTAINER_NAME}) ]; then
    echo "Stopping existing container..."
    docker stop ${CONTAINER_NAME} || true
fi

# Remove container if exists
if [ $(docker ps -aq -f name=${CONTAINER_NAME}) ]; then
    echo "Removing existing container..."
    docker rm -f ${CONTAINER_NAME} || true
fi

sleep 2

echo "Pulling latest image..."
docker pull ${DOCKERHUB_USER}/dev:latest

echo "Starting new container..."
docker run -d \
    --name ${CONTAINER_NAME} \
    --restart always \
    -p 80:80 \
    ${DOCKERHUB_USER}/dev:latest

echo "===== Deployment Complete ====="
echo "App running at: http://$(curl -s ifconfig.me):80"
