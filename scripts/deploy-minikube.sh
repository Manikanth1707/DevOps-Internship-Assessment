#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/deploy-minikube.sh [IMAGE_TAG]
#
# IMAGE_TAG defaults to 'latest'. Example: 'sha-abcdef' or 'main'.

IMAGE_REGISTRY="ghcr.io/manikanth1707/devops-internship-assessment"
IMAGE_TAG="${1:-latest}"
K8S_DIR="k8s"

info() { echo -e "[INFO] $*"; }
warn() { echo -e "[WARN] $*"; }

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		return 1
	fi
}

install_kubectl() {
	if require_cmd kubectl; then return; fi
	warn "kubectl not found. Installing..."
	# Ubuntu/Debian default install
	sudo apt-get update -y
	sudo apt-get install -y ca-certificates curl
	curl -fsSL https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o kubectl
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/kubectl
	info "kubectl $(kubectl version --client --output=yaml | head -n 1) installed"
}

install_minikube() {
	if require_cmd minikube; then return; fi
	warn "minikube not found. Installing..."
	curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	chmod +x minikube
	sudo mv minikube /usr/local/bin/
	info "minikube $(minikube version) installed"
}

start_minikube() {
	if ! minikube status >/dev/null 2>&1; then
		info "Starting Minikube..."
		minikube start
	else
		info "Minikube already running"
	fi
}

update_image_tag_in_deployment() {
	local file="$K8S_DIR/deployment.yaml"
	if [[ ! -f "$file" ]]; then
		echo "deployment.yaml not found at $file" >&2
		exit 1
	fi
	info "Setting image to ${IMAGE_REGISTRY}:${IMAGE_TAG} in deployment.yaml (in-memory)"
	# Apply with override using kubectl set image
	kubectl set image -f "$file" nextjs-app=${IMAGE_REGISTRY}:${IMAGE_TAG} --local -o yaml | kubectl apply -f -
}

apply_manifests() {
	info "Applying Service"
	kubectl apply -f "$K8S_DIR/service.yaml"
}

wait_rollout() {
	info "Waiting for rollout..."
	kubectl rollout status deployment/nextjs-app
}

print_access() {
	local ip
	ip=$(minikube ip)
	info "Open: http://${ip}:30080"
}

main() {
	install_kubectl
	install_minikube
	start_minikube
	update_image_tag_in_deployment
	apply_manifests
	wait_rollout
	print_access
}

main "$@"
