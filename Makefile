# Makefile for Save The Elephant - PostgreSQL Helm Chart
# This Makefile helps with local development and testing using Minikube

.PHONY: help minikube-start minikube-stop minikube-status deploy deploy-basic deploy-replication uninstall clean status logs connect get-password test package lint

# Variables
CHART_NAME := save-the-elephant
RELEASE_NAME := metadb
NAMESPACE := default
MINIKUBE_PROFILE := minikube
MINIKUBE_MEMORY := 4096
MINIKUBE_CPUS := 2
MINIKUBE_DRIVER := podman

# MinIO variables for local S3 testing
MINIO_CONTAINER := minio-local
MINIO_PORT := 9000
MINIO_CONSOLE_PORT := 9001
MINIO_ACCESS_KEY := minioadmin
MINIO_SECRET_KEY := minioadmin
MINIO_BUCKET := postgres-backups

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

## help: Show this help message
help:
	@echo "$(GREEN)Save The Elephant - PostgreSQL Helm Chart$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed -E 's/^## (.*)/  \1/'
	@echo ""

## minikube-start: Start minikube cluster
minikube-start:
	@echo "$(GREEN)Starting minikube cluster...$(NC)"
	@if minikube status -p $(MINIKUBE_PROFILE) >/dev/null 2>&1; then \
		echo "$(YELLOW)Minikube cluster '$(MINIKUBE_PROFILE)' is already running$(NC)"; \
	else \
		minikube start -p $(MINIKUBE_PROFILE) \
			--memory=$(MINIKUBE_MEMORY) \
			--cpus=$(MINIKUBE_CPUS) \
			--driver=p$(MINIKUBE_DRIVER); \
		echo "$(GREEN)Minikube cluster started successfully$(NC)"; \
	fi
	@echo "$(GREEN)Setting kubectl context...$(NC)"
	@kubectl config use-context $(MINIKUBE_PROFILE)
	@echo "$(GREEN)Cluster info:$(NC)"
	@kubectl cluster-info

## minikube-stop: Stop minikube cluster
minikube-stop:
	@echo "$(YELLOW)Stopping minikube cluster...$(NC)"
	@minikube stop -p $(MINIKUBE_PROFILE)
	@echo "$(GREEN)Minikube cluster stopped$(NC)"

## minikube-delete: Delete minikube cluster
minikube-delete:
	@echo "$(RED)Deleting minikube cluster...$(NC)"
	@minikube delete -p $(MINIKUBE_PROFILE)
	@echo "$(GREEN)Minikube cluster deleted$(NC)"

## minikube-clean-volumes: Clean up conflicting Podman volumes
minikube-clean-volumes:
	@echo "$(YELLOW)Cleaning up Podman volumes...$(NC)"
	@if podman info >/dev/null 2>&1; then \
		podman volume rm minikube 2>/dev/null || echo "$(YELLOW)Volume 'minikube' not found or already removed$(NC)"; \
		podman volume prune -f; \
		echo "$(GREEN)Podman volumes cleaned$(NC)"; \
	else \
		echo "$(RED)Podman is not available. Please install podman.$(NC)"; \
		exit 1; \
	fi

## minikube-fix-volume: Fix volume conflict (stops cluster, cleans volumes, restarts)
minikube-fix-volume:
	@echo "$(YELLOW)Fixing Podman volume conflict...$(NC)"
	@echo "Step 1: Stopping existing minikube cluster"
	@minikube stop -p $(MINIKUBE_PROFILE) 2>/dev/null || echo "$(YELLOW)Cluster not running$(NC)"
	@echo "Step 2: Deleting minikube cluster"
	@minikube delete -p $(MINIKUBE_PROFILE) 2>/dev/null || echo "$(YELLOW)Cluster not found$(NC)"
	@echo "Step 3: Cleaning Podman volumes"
	@$(MAKE) minikube-clean-volumes
	@echo "Step 4: Starting fresh minikube cluster"
	@$(MAKE) minikube-start
	@echo "$(GREEN)Volume conflict fixed!$(NC)"

## minikube-status: Show minikube cluster status
minikube-status:
	@echo "$(GREEN)Minikube cluster status:$(NC)"
	@minikube status -p $(MINIKUBE_PROFILE) || echo "$(RED)Cluster is not running$(NC)"

## minikube-dashboard: Open Kubernetes dashboard in browser
minikube-dashboard:
	@echo "$(GREEN)Starting Kubernetes dashboard...$(NC)"
	@echo "$(YELLOW)Dashboard will open in your default browser$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop the dashboard proxy$(NC)"
	@kubectl config use-context $(MINIKUBE_PROFILE)
	@minikube dashboard -p $(MINIKUBE_PROFILE)

## minikube-dashboard-url: Get dashboard URL (keeps running, press Ctrl+C to stop)
minikube-dashboard-url:
	@echo "$(GREEN)Starting dashboard proxy...$(NC)"
	@echo "$(YELLOW)Copy the URL below and paste in your browser$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop the dashboard proxy$(NC)"
	@echo ""
	@kubectl config use-context $(MINIKUBE_PROFILE)
	@minikube dashboard -p $(MINIKUBE_PROFILE) --url

## minikube-addons: Enable useful minikube addons
minikube-addons:
	@echo "$(GREEN)Enabling minikube addons...$(NC)"
	@minikube -p $(MINIKUBE_PROFILE) addons enable metrics-server
	@minikube -p $(MINIKUBE_PROFILE) addons enable dashboard
	@echo "$(GREEN)Addons enabled$(NC)"

## minio-start: Start MinIO container for local S3 testing
minio-start:
	@echo "$(GREEN)Starting MinIO container...$(NC)"
	@if podman ps -a --format "{{.Names}}" | grep -q "^$(MINIO_CONTAINER)$$"; then \
		echo "$(YELLOW)MinIO container already exists$(NC)"; \
		if podman ps --format "{{.Names}}" | grep -q "^$(MINIO_CONTAINER)$$"; then \
			echo "$(YELLOW)MinIO is already running$(NC)"; \
		else \
			echo "$(GREEN)Starting existing MinIO container...$(NC)"; \
			podman start $(MINIO_CONTAINER); \
		fi; \
	else \
		echo "$(GREEN)Creating new MinIO container...$(NC)"; \
		podman run -d \
			--name $(MINIO_CONTAINER) \
			-p $(MINIO_PORT):9000 \
			-p $(MINIO_CONSOLE_PORT):9001 \
			-e MINIO_ROOT_USER=$(MINIO_ACCESS_KEY) \
			-e MINIO_ROOT_PASSWORD=$(MINIO_SECRET_KEY) \
			quay.io/minio/minio:latest \
			server /data --console-address ":9001"; \
		sleep 5; \
		echo "$(GREEN)Creating bucket $(MINIO_BUCKET)...$(NC)"; \
		podman exec $(MINIO_CONTAINER) mkdir -p /data/$(MINIO_BUCKET); \
	fi
	@echo "$(GREEN)MinIO is running!$(NC)"
	@echo "$(YELLOW)MinIO Console: http://localhost:$(MINIO_CONSOLE_PORT)$(NC)"
	@echo "$(YELLOW)Access Key: $(MINIO_ACCESS_KEY)$(NC)"
	@echo "$(YELLOW)Secret Key: $(MINIO_SECRET_KEY)$(NC)"
	@echo "$(YELLOW)Bucket: $(MINIO_BUCKET)$(NC)"

## minio-stop: Stop MinIO container
minio-stop:
	@echo "$(YELLOW)Stopping MinIO container...$(NC)"
	@podman stop $(MINIO_CONTAINER) 2>/dev/null || echo "$(YELLOW)MinIO container not running$(NC)"
	@echo "$(GREEN)MinIO stopped$(NC)"

## minio-remove: Remove MinIO container and data
minio-remove: minio-stop
	@echo "$(RED)Removing MinIO container...$(NC)"
	@podman rm $(MINIO_CONTAINER) 2>/dev/null || echo "$(YELLOW)MinIO container not found$(NC)"
	@echo "$(GREEN)MinIO container removed$(NC)"

## minio-logs: Show MinIO logs
minio-logs:
	@echo "$(GREEN)MinIO logs:$(NC)"
	@podman logs $(MINIO_CONTAINER) --tail=50

## minio-status: Check MinIO status
minio-status:
	@echo "$(GREEN)MinIO Status:$(NC)"
	@if podman ps --format "{{.Names}}" | grep -q "^$(MINIO_CONTAINER)$$"; then \
		echo "$(GREEN)MinIO is running$(NC)"; \
		podman ps --filter name=$(MINIO_CONTAINER) --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
	else \
		echo "$(RED)MinIO is not running$(NC)"; \
	fi

## package: Package the Helm chart
package:
	@echo "$(GREEN)Packaging Helm chart...$(NC)"
	@helm package $(CHART_NAME)
	@echo "$(GREEN)Chart packaged successfully$(NC)"
	@ls -lh $(CHART_NAME)-*.tgz

## lint: Lint the Helm chart
lint:
	@echo "$(GREEN)Linting Helm chart...$(NC)"
	@helm lint $(CHART_NAME)

## template: Generate Kubernetes manifests from the chart
template:
	@echo "$(GREEN)Generating templates...$(NC)"
	@helm template $(RELEASE_NAME) ./$(CHART_NAME)

## deploy: Deploy PostgreSQL with default values
deploy: minikube-start
	@echo "$(GREEN)Deploying $(CHART_NAME) to minikube...$(NC)"
	@helm upgrade --install $(RELEASE_NAME) ./$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--atomic \
		--wait \
		--timeout 5m
	@echo "$(GREEN)Deployment complete!$(NC)"
	@echo ""
	@$(MAKE) status

## deploy-replication: Deploy with replication (1 primary + 2 replicas)
deploy-replication: minikube-start
	@echo "$(GREEN)Deploying with replication enabled...$(NC)"
	@helm upgrade --install $(RELEASE_NAME) ./$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values examples/replication.values.yaml \
		--wait \
		--atomic \
		--timeout 3m
	@echo "$(GREEN)Deployment complete!$(NC)"
	@echo ""
	@$(MAKE) status

## deploy-with-backup: Deploy with replication and hourly S3 backups to MinIO
deploy-with-backup: minikube-start minio-start
	@echo "$(GREEN)Deploying with replication and S3 backups...$(NC)"
	@echo "$(YELLOW)Getting host IP for MinIO access from minikube...$(NC)"
	@HOST_IP=$$(minikube ssh "ip route | grep default | awk '{print \$$3}'" 2>/dev/null | tr -d '[:space:]' || echo "192.168.65.2"); \
	echo "$(YELLOW)Using MinIO endpoint: http://$$HOST_IP:$(MINIO_PORT)$(NC)"; \
	helm upgrade --install $(RELEASE_NAME) ./$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values examples/replication-and-backup.values.yaml \
		--set backup.s3.endpoint="http://$$HOST_IP:$(MINIO_PORT)" \
		--set backup.s3.accessKeyId=$(MINIO_ACCESS_KEY) \
		--set backup.s3.secretAccessKey=$(MINIO_SECRET_KEY) \
		--set backup.s3.bucket=$(MINIO_BUCKET) \
		--wait \
		--atomic \
		--timeout 5m
	@echo "$(GREEN)Deployment complete!$(NC)"
	@echo ""
	@echo "$(YELLOW)Backup is configured for hourly snapshots to MinIO$(NC)"
	@echo "$(YELLOW)MinIO Console: http://localhost:$(MINIO_CONSOLE_PORT)$(NC)"
	@echo ""
	@$(MAKE) status

## uninstall: Uninstall the Helm release
uninstall:
	@echo "$(YELLOW)Uninstalling $(RELEASE_NAME)...$(NC)"
	@helm uninstall $(RELEASE_NAME) -n $(NAMESPACE) || echo "$(YELLOW)Release not found$(NC)"
	@echo "$(GREEN)Uninstall complete$(NC)"

## clean: Uninstall and delete PVCs
clean: uninstall
	@echo "$(YELLOW)Deleting persistent volume claims...$(NC)"
	@kubectl delete pvc -l app.kubernetes.io/name=$(CHART_NAME) -n $(NAMESPACE) --ignore-not-found
	@echo "$(GREEN)Cleanup complete$(NC)"

## status: Show deployment status
status:
	@echo "$(GREEN)Deployment Status:$(NC)"
	@echo ""
	@echo "$(YELLOW)Helm Release:$(NC)"
	@helm list -n $(NAMESPACE) | grep $(RELEASE_NAME) || echo "$(RED)No release found$(NC)"
	@echo ""
	@echo "$(YELLOW)Pods:$(NC)"
	@kubectl get pods -l app.kubernetes.io/name=$(CHART_NAME) -n $(NAMESPACE) -o wide
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@kubectl get svc -l app.kubernetes.io/name=$(CHART_NAME) -n $(NAMESPACE)
	@echo ""
	@echo "$(YELLOW)PVCs:$(NC)"
	@kubectl get pvc -l app.kubernetes.io/name=$(CHART_NAME) -n $(NAMESPACE)
	@echo ""
	@echo "$(YELLOW)StatefulSet:$(NC)"
	@kubectl get statefulset -l app.kubernetes.io/name=$(CHART_NAME) -n $(NAMESPACE)

## logs: Show logs from primary pod
logs:
	@echo "$(GREEN)Showing logs from primary pod...$(NC)"
	@kubectl logs $(RELEASE_NAME)-$(CHART_NAME)-postgresql-0 -n $(NAMESPACE) --tail=50

## logs-follow: Follow logs from primary pod
logs-follow:
	@echo "$(GREEN)Following logs from primary pod...$(NC)"
	@kubectl logs $(RELEASE_NAME)-$(CHART_NAME)-postgresql-0 -n $(NAMESPACE) -f

## logs-replica: Show logs from first replica pod (if exists)
logs-replica:
	@echo "$(GREEN)Showing logs from replica pod...$(NC)"
	@kubectl logs $(RELEASE_NAME)-$(CHART_NAME)-postgresql-1 -n $(NAMESPACE) --tail=50 || echo "$(RED)Replica pod not found$(NC)"

## get-password: Get PostgreSQL password
get-password:
	@echo "$(GREEN)PostgreSQL Password:$(NC)"
	@kubectl get secret $(RELEASE_NAME)-$(CHART_NAME)-postgresql -n $(NAMESPACE) -o jsonpath="{.data.postgres-password}" | base64 -d
	@echo ""

## connect: Connect to PostgreSQL using psql
connect:
	@echo "$(GREEN)Connecting to PostgreSQL...$(NC)"
	@kubectl run $(RELEASE_NAME)-client --rm --tty -i --restart='Never' \
		--namespace $(NAMESPACE) \
		--image postgres:17.4 \
		--env="PGPASSWORD=$$(kubectl get secret $(RELEASE_NAME)-$(CHART_NAME)-postgresql -n $(NAMESPACE) -o jsonpath='{.data.postgres-password}' | base64 -d)" \
		--command -- psql -h $(RELEASE_NAME)-$(CHART_NAME)-postgresql -U postgres -d postgres

## port-forward: Port forward PostgreSQL to localhost:5432
port-forward:
	@echo "$(GREEN)Port forwarding PostgreSQL to localhost:5432...$(NC)"
	@echo "$(YELLOW)Connect using: psql -h localhost -U postgres -d postgres$(NC)"
	@echo "$(YELLOW)Password: $$(kubectl get secret $(RELEASE_NAME)-$(CHART_NAME)-postgresql -n $(NAMESPACE) -o jsonpath='{.data.postgres-password}' | base64 -d)$(NC)"
	@echo ""
	@kubectl port-forward svc/$(RELEASE_NAME)-$(CHART_NAME)-postgresql 5432:5432 -n $(NAMESPACE)

## test: Run Helm tests
test:
	@echo "$(GREEN)Running Helm tests...$(NC)"
	@helm test $(RELEASE_NAME) -n $(NAMESPACE)

## check-replication: Check replication status
check-replication:
	@echo "$(GREEN)Checking replication status...$(NC)"
	@echo ""
	@echo "$(YELLOW)Replication status on primary:$(NC)"
	@kubectl exec $(RELEASE_NAME)-$(CHART_NAME)-postgresql-0 -n $(NAMESPACE) -- \
		psql -U postgres -c "SELECT * FROM pg_stat_replication;" || echo "$(RED)Failed to check replication$(NC)"
	@echo ""
	@echo "$(YELLOW)Replication status on replica (if exists):$(NC)"
	@kubectl exec $(RELEASE_NAME)-$(CHART_NAME)-postgresql-1 -n $(NAMESPACE) -- \
		psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;" || echo "$(YELLOW)No replica found or replication not configured$(NC)"

## check-backups: Check backup CronJob status and recent jobs
check-backups:
	@echo "$(GREEN)Checking backup status...$(NC)"
	@echo ""
	@echo "$(YELLOW)Backup CronJob:$(NC)"
	@kubectl get cronjob -l app.kubernetes.io/name=$(CHART_NAME) -n $(NAMESPACE) || echo "$(RED)No backup CronJob found$(NC)"
	@echo ""
	@echo "$(YELLOW)Recent backup jobs:$(NC)"
	@kubectl get jobs -l app.kubernetes.io/name=$(CHART_NAME),app.kubernetes.io/component=backup -n $(NAMESPACE) --sort-by=.metadata.creationTimestamp || echo "$(RED)No backup jobs found$(NC)"
	@echo ""
	@echo "$(YELLOW)Recent backup pods:$(NC)"
	@kubectl get pods -l app.kubernetes.io/name=$(CHART_NAME),app.kubernetes.io/component=backup -n $(NAMESPACE) --sort-by=.metadata.creationTimestamp || echo "$(RED)No backup pods found$(NC)"

## trigger-backup: Manually trigger a backup job
trigger-backup:
	@echo "$(GREEN)Triggering manual backup...$(NC)"
	@kubectl create job --from=cronjob/$(RELEASE_NAME)-$(CHART_NAME)-backup manual-backup-$$(date +%s) -n $(NAMESPACE)
	@echo "$(GREEN)Backup job created!$(NC)"
	@echo "$(YELLOW)Check status with: make check-backups$(NC)"

## backup-logs: Show logs from most recent backup job
backup-logs:
	@echo "$(GREEN)Showing backup logs...$(NC)"
	@BACKUP_POD=$$(kubectl get pods -l app.kubernetes.io/name=$(CHART_NAME),app.kubernetes.io/component=backup -n $(NAMESPACE) --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null); \
	if [ -n "$$BACKUP_POD" ]; then \
		kubectl logs $$BACKUP_POD -n $(NAMESPACE); \
	else \
		echo "$(RED)No backup pods found$(NC)"; \
	fi

## list-backups-minio: List backups in MinIO
list-backups-minio:
	@echo "$(GREEN)Listing backups in MinIO...$(NC)"
	@podman exec $(MINIO_CONTAINER) ls -lh /data/$(MINIO_BUCKET)/save-the-elephant/ 2>/dev/null || echo "$(YELLOW)No backups found or MinIO not running$(NC)"

## describe-pod: Describe primary pod
describe-pod:
	@echo "$(GREEN)Describing primary pod...$(NC)"
	@kubectl describe pod $(RELEASE_NAME)-$(CHART_NAME)-postgresql-0 -n $(NAMESPACE)

## shell: Get shell access to primary pod
shell:
	@echo "$(GREEN)Opening shell to primary pod...$(NC)"
	@kubectl exec -it $(RELEASE_NAME)-$(CHART_NAME)-postgresql-0 -n $(NAMESPACE) -- /bin/bash

## watch: Watch pod status
watch:
	@echo "$(GREEN)Watching pod status...$(NC)"
	@kubectl get pods -l app.kubernetes.io/name=$(CHART_NAME) -n $(NAMESPACE) -w

## full-deploy: Complete deployment workflow (start minikube, deploy, show status)
full-deploy: minikube-start deploy
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Deployment Complete!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)PostgreSQL Password:$(NC)"
	@$(MAKE) get-password
	@echo ""
	@echo "$(YELLOW)To connect to PostgreSQL:$(NC)"
	@echo "  make connect"
	@echo ""
	@echo "$(YELLOW)To port-forward to localhost:$(NC)"
	@echo "  make port-forward"
	@echo ""
	@echo "$(YELLOW)To check logs:$(NC)"
	@echo "  make logs"

## full-deploy-replication: Complete deployment with replication
full-deploy-replication: minikube-start deploy-replication
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Replication Deployment Complete!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)PostgreSQL Password:$(NC)"
	@$(MAKE) get-password
	@echo ""
	@echo "$(YELLOW)Check replication status:$(NC)"
	@echo "  make check-replication"
	@echo ""
	@echo "$(YELLOW)To connect to PostgreSQL:$(NC)"
	@echo "  make connect"

## quick-test: Quick test workflow (lint, package, deploy, test)
quick-test: lint package deploy test
	@echo "$(GREEN)Quick test completed successfully!$(NC)"

## reset: Complete reset (delete cluster and start fresh)
reset: minikube-delete minikube-start
	@echo "$(GREEN)Environment reset complete!$(NC)"
