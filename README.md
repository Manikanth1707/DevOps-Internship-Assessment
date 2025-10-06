# DevOps Internship Assessment - Next.js + Docker + GHCR + Minikube

This repository contains a minimal Next.js app containerized with Docker, built and pushed via GitHub Actions to GitHub Container Registry (GHCR), and deployed to Kubernetes using Minikube.

## Repo & Image
- Repo: `Manikanth1707/DevOps-Internship-Assessment`
- Image: `ghcr.io/manikanth1707/devops-internship-assessment`

## Project Structure
```
nextjs-app/
  Dockerfile
  .dockerignore
  .github/workflows/ci.yml
  k8s/
    deployment.yaml
    service.yaml
  src/app/*
```

## Prerequisites
- A GitHub repository with Actions enabled.
- GHCR permissions (default `GITHUB_TOKEN` is enough in the same repo).
- Server with Minikube & kubectl for deployment.

## Local Development (no Docker required)
```bash
cd nextjs-app
npm install
npm run dev
# App at http://localhost:3000
```

## Build & Run Locally with Docker (optional)
```bash
# From nextjs-app/
docker build -t nextjs-app:local .
docker run --rm -p 3000:3000 nextjs-app:local
```

## GitHub Actions (CI to GHCR)
- Workflow: `.github/workflows/ci.yml`
- Triggers on push to `main`
- Tags: `latest`, branch name, and commit `sha`

### Steps
1. Push code to `main`.
2. GitHub Actions builds and pushes image to GHCR: `ghcr.io/<owner>/<repo>:<tag>`.
3. Confirm image exists in the Packages section of the repo.

## Kubernetes Deployment on Minikube
### Start Minikube
```bash
minikube start
```

### Pull GHCR image into Minikube
If your cluster cannot pull from GHCR anonymously, create a pull secret:
```bash
kubectl create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username=<GITHUB_USERNAME> \
  --docker-password=<GHCR_TOKEN_OR_GITHUB_TOKEN> \
  --docker-email=<EMAIL>
```
Add the secret name to `imagePullSecrets` in `k8s/deployment.yaml` if needed.

### Apply manifests
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Wait for pods
```bash
kubectl rollout status deployment/nextjs-app
kubectl get pods -l app=nextjs-app
```

### Access the app
Using NodePort (configured 30080):
```bash
minikube ip
# Then open http://<minikube-ip>:30080
```

Or use Minikube service helper:
```bash
minikube service nextjs-app
```

## Notes
- Dockerfile uses multi-stage build and Next.js standalone output.
- Health checks are HTTP GET `/` on port 3000.
- Update image tag in `k8s/deployment.yaml` to a specific `:sha` for immutable deploys.
