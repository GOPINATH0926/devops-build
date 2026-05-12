# 🚀 DevOps Build — CI/CD Pipeline Project

A complete end-to-end DevOps pipeline that automatically builds, pushes, and deploys a React web application using Jenkins, Docker, and GitHub — with branch-based logic for dev and production environments, and Prometheus + Grafana for monitoring.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Branch Strategy](#branch-strategy)
- [Setup Instructions](#setup-instructions)
  - [1. Application Setup](#1-application-setup)
  - [2. Docker Setup](#2-docker-setup)
  - [3. Bash Scripts](#3-bash-scripts)
  - [4. Jenkins Setup](#4-jenkins-setup)
  - [5. GitHub Webhook](#5-github-webhook)
  - [6. AWS EC2 & Security Group](#6-aws-ec2--security-group)
  - [7. Monitoring](#7-monitoring)
- [Pipeline Explanation](#pipeline-explanation)
- [Project URLs](#project-urls)
- [Screenshots](#screenshots)

---

## Project Overview

This project deploys a production-ready React application using a fully automated CI/CD pipeline. The pipeline uses a **two-branch strategy**:

- Pushing to `dev` branch → builds image → pushes to **public dev DockerHub repo** → deploys to EC2
- Merging `dev` into `master` → pushes image to **private prod DockerHub repo**

---

## Architecture

```
Developer pushes code
        ↓
   GitHub Repository
   (dev / master branch)
        ↓
  Jenkins Multibranch Pipeline
  (webhook auto-trigger)
        ↓
  build.sh → Docker Image Built
        ↓
  ┌─────────────────────────────┐
  │  dev branch?                │
  │  → Push to DockerHub/dev    │
  │  → Deploy to EC2 port 80    │
  │                             │
  │  master branch?             │
  │  → Push to DockerHub/prod   │
  └─────────────────────────────┘
        ↓
  deploy.sh → App live on EC2
        ↓
  Prometheus + Grafana Monitoring
```

---

## Tech Stack

| Tool | Purpose |
|---|---|
| **GitHub** | Version control with dev and master branches |
| **Jenkins** | CI/CD automation (Multibranch Pipeline) |
| **Docker** | Application containerization |
| **Docker Compose** | Multi-container deployment |
| **DockerHub** | Image registry (dev=public, prod=private) |
| **AWS EC2** | Application server (t2.micro, Ubuntu) |
| **Nginx** | Web server inside Docker container |
| **Prometheus** | Metrics collection |
| **Grafana** | Monitoring dashboards |
| **Alertmanager** | Alert notifications when app goes down |
| **Node Exporter** | EC2 system metrics |

---

## Project Structure

```
devops-build/
├── build/                   # Pre-built React app (static files)
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Docker Compose for deployment
├── build.sh                 # Script to build Docker image
├── deploy.sh                # Script to deploy container
├── Jenkinsfile              # Declarative pipeline script
├── .gitignore               # Git ignore rules
├── .dockerignore            # Docker ignore rules
└── README.md                # Project documentation
```

---

## Branch Strategy

| Branch | Action | DockerHub Repo | Deploy |
|---|---|---|---|
| `dev` | Push code | `gopinathsiva2605/dev` (public) | Yes — EC2 port 80 |
| `master` | Merge from dev | `gopinathsiva2605/prod` (private) | No (prod image only) |

---

## Setup Instructions

### 1. Application Setup

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@13.203.93.113

# Clone source repo
git clone https://github.com/sriram-R-krishnan/devops-build.git
cd devops-build

# Set your own remote
git remote remove origin
git remote add origin https://github.com/GOPINATH0926/devops-build.git

# Create and push dev branch
git checkout -b dev
git push -u origin dev
```

---

### 2. Docker Setup

**Dockerfile:**

```dockerfile
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY build/ /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

> Uses nginx:alpine to serve the pre-built React static files. Lightweight and production-ready.

**docker-compose.yml:**

```yaml
services:
  app:
    image: gopinathsiva2605/dev:latest
    ports:
      - "80:80"
    restart: always
    container_name: devops-app
```

**Build and push manually:**

```bash
docker build -t gopinathsiva2605/dev:latest .
docker login
docker push gopinathsiva2605/dev:latest
```

**.dockerignore:**

```
node_modules/
.git/
*.md
.gitignore
```

**.gitignore:**

```
node_modules/
build/
.env
*.log
.DS_Store
```

---

### 3. Bash Scripts

**build.sh** — Builds and tags Docker image:

```bash
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
```

**deploy.sh** — Stops old container and runs new one:

```bash
#!/bin/bash
set -e

DOCKERHUB_USER="gopinathsiva2605"
CONTAINER_NAME="devops-app"

echo "===== Deploying Application ====="

if [ $(docker ps -q -f name=${CONTAINER_NAME}) ]; then
    echo "Stopping existing container..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi

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
```

Make scripts executable:

```bash
chmod +x build.sh deploy.sh
```

---

### 4. Jenkins Setup

**Jenkins installed on EC2 at:** `http://13.203.93.113:8080`

**Plugins installed:**
- Git Plugin
- GitHub Integration Plugin
- GitHub Branch Source Plugin
- Pipeline Plugin
- Docker Pipeline Plugin
- Multibranch Pipeline Plugin
- Credentials Binding Plugin

**Credentials added:**
- DockerHub: Username/password → ID: `dockerhub-creds`
- GitHub PAT: Username/password → ID: `githubpat`

**Jenkinsfile (Declarative Multibranch Pipeline):**

```groovy
pipeline {
    agent any
    environment {
        DOCKERHUB_USER = "gopinathsiva2605"
        DEV_IMAGE = "gopinathsiva2605/dev"
        PROD_IMAGE = "gopinathsiva2605/prod"
        IMAGE_TAG = "${GIT_COMMIT[0..6]}"
    }
    stages {
        stage('Clone') {
            steps {
                echo "Building branch: ${GIT_BRANCH}"
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "chmod +x build.sh"
                sh "./build.sh ${GIT_BRANCH}"
            }
        }
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    script {
                        if (env.GIT_BRANCH == 'dev') {
                            sh "docker push ${DEV_IMAGE}:latest"
                            echo "Pushed to DEV repo"
                        } else if (env.GIT_BRANCH == 'master') {
                            sh "docker tag ${DEV_IMAGE}:latest ${PROD_IMAGE}:latest"
                            sh "docker push ${PROD_IMAGE}:latest"
                            echo "Pushed to PROD repo"
                        }
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                sh "chmod +x deploy.sh"
                sh "./deploy.sh"
            }
        }
    }
    post {
        success { echo "Pipeline succeeded on branch: ${GIT_BRANCH}" }
        failure { echo "Pipeline failed on branch: ${GIT_BRANCH}" }
    }
}
```

**Pipeline stages explained:**

| Stage | What it does |
|---|---|
| Clone | Logs the current branch being built |
| Build Docker Image | Runs build.sh — builds and tags image with git commit hash |
| Push to DockerHub | dev branch → pushes to dev repo; master → pushes to prod repo |
| Deploy | Runs deploy.sh — stops old container, pulls new image, starts container |

---

### 5. GitHub Webhook

Enables automatic pipeline trigger on every `git push`.

**Setup:**
1. GitHub repo → Settings → Webhooks → Add webhook
2. Payload URL: `http://13.203.93.113:8080/github-webhook/`
3. Content type: `application/json`
4. Event: Just the push event
5. Save

**In Jenkins:**
- devops-pipeline → Configure → Branch Sources → Credentials: select `githubpat`
- Manage Jenkins → System → GitHub → select `githubpat` → Manage hooks ✅

**How it works:**
```
git push origin dev
      ↓
GitHub sends POST to Jenkins webhook URL
      ↓
Jenkins detects branch (dev or master)
      ↓
Correct pipeline triggers automatically
```

---

### 6. AWS EC2 & Security Group

**Instance:** t2.micro, Ubuntu, ap-south-1

**Security Group Rules:**

| Type | Port | Source | Purpose |
|---|---|---|---|
| HTTP | 80 | 0.0.0.0/0 | Anyone can access the app |
| SSH | 22 | Your IP only | Only you can SSH in |
| Custom TCP | 8080 | 0.0.0.0/0 | Jenkins access |
| Custom TCP | 9090 | Your IP only | Prometheus |
| Custom TCP | 3000 | Your IP only | Grafana |

---

### 7. Monitoring

Prometheus, Grafana, Alertmanager, and Node Exporter deployed via Docker Compose.

**monitoring/docker-compose.yml:**

```yaml
services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: always

  alertmanager:
    image: prom/alertmanager
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    restart: always

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3000:3000"
    restart: always

  node-exporter:
    image: prom/node-exporter
    container_name: node-exporter
    ports:
      - "9100:9100"
    restart: always
```

**alert_rules.yml** — Sends alert when app goes down:

```yaml
groups:
  - name: app_alerts
    rules:
      - alert: AppDown
        expr: up{job="app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Application is DOWN!"
          description: "The devops-app has been down for more than 1 minute."
```

**Start monitoring:**

```bash
cd ~/monitoring
docker-compose up -d
```

**Access:**
- Prometheus: `http://13.203.93.113:9090`
- Grafana: `http://13.203.93.113:3000` (admin/admin)
- Alertmanager: `http://13.203.93.113:9093`

---

## Pipeline Explanation

The CI/CD pipeline follows this automated flow:

1. Developer pushes code to `dev` or `master` branch on GitHub
2. GitHub sends a webhook POST to Jenkins at `:8080/github-webhook/`
3. Jenkins Multibranch Pipeline detects the branch automatically
4. **Clone stage** — Jenkins pulls the latest code
5. **Build stage** — `build.sh` runs Docker build, tags image with git commit hash
6. **Push stage** — if `dev` branch → pushes to public `gopinathsiva2605/dev` repo; if `master` → pushes to private `gopinathsiva2605/prod` repo
7. **Deploy stage** — `deploy.sh` stops old container, pulls new image, starts fresh container on port 80
8. App is live at `http://13.203.93.113:80`
9. Prometheus scrapes metrics every 15 seconds
10. Grafana displays real-time dashboards
11. Alertmanager sends notification if app goes down

---

## Project URLs

| Service | URL |
|---|---|
| **Deployed Application** | http://13.203.93.113:80 |
| **Jenkins** | http://13.203.93.113:8080 |
| **DockerHub Dev Repo** | https://hub.docker.com/r/gopinathsiva2605/dev |
| **DockerHub Prod Repo** | https://hub.docker.com/r/gopinathsiva2605/prod |
| **GitHub Repository** | https://github.com/GOPINATH0926/devops-build |
| **Prometheus** | http://13.203.93.113:9090 |
| **Grafana** | http://13.203.93.113:3000 |

---

## Author

**Gopinath**
HCLTech | Cisco Jasper
GitHub: [@GOPINATH0926](https://github.com/GOPINATH0926)
