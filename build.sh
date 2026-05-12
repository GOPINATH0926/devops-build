#!/bin/bash
set -e

BRANCH=$1
DOCKERHUB_USER="gopinathsiva2605"
IMAGE_TAG=$(git rev-parse --short HEAD)

echo "===== Building Docker Image ====="
echo "Branch: $BRANCH"
echo "Tag: $IMAGE_TAG"

docker build -t ${DOCKERHUB_USER}/dev:${IMAGE_TAG} .
docker tag ${DOCKERHUB_USER}/dev:${IMAGE_TAG} ${DOCKERHUB_USER}/dev:latest

echo "===== Build Complete ====="
