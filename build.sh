#!/bin/bash

# Build script for Docker image
set -e  # Stop on any error

BRANCH=$1
DOCKERHUB_USER="gopinathsiva2605"
IMAGE_TAG=$(git rev-parse --short HEAD)  # Use git commit hash as tag

echo "===== Building Docker Image ====="
echo "Branch: $BRANCH"
echo "Tag: $IMAGE_TAG"

# Build the image
docker build -t ${DOCKERHUB_USER}/dev:${IMAGE_TAG} .
docker tag ${DOCKERHUB_USER}/dev:${IMAGE_TAG} ${DOCKERHUB_USER}/dev:latest

echo "===== Build Complete ====="
echo "Image: ${DOCKERHUB_USER}/dev:${IMAGE_TAG}"
