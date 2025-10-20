# Makefile Guide - Save The Elephant

This guide explains how to use the Makefile for local development and testing with Minikube.

## Prerequisites

Before using the Makefile, ensure you have the following installed:

1. **Podman** - Container runtime for running MinIO and Minikube
2. **Minikube** - For local Kubernetes cluster
3. **kubectl** - Kubernetes CLI
4. **Helm** - Version 3.0+
5. **Make** - Usually pre-installed on macOS/Linux

### Installation Commands

**macOS (using Homebrew):**
```bash
brew install podman minikube kubectl helm
```

**Linux:**
```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Podman
sudo apt-get install podman  # Debian/Ubuntu
# OR
sudo dnf install podman      # Fedora/RHEL
```

## Quick Start

### 1. View Available Commands

```bash
make help
```

This shows all available Make targets with descriptions.

### 2. Complete Deployment Workflow

```bash
# Deploy PostgreSQL (single instance)
make full-deploy
```

This will:
- Start minikube if not running (using podman driver)
- Deploy PostgreSQL with default settings
- Show deployment status
- Display connection instructions

### 3. Connect to PostgreSQL

```bash
make connect
```

### 4. Clean Up

```bash
# Uninstall the release but keep minikube running
make uninstall

# Uninstall and delete persistent volumes
make clean

# Stop minikube
make minikube-stop
```

## Available Commands

### Minikube Management

| Command | Description |
|---------|-------------|
| `make minikube-start` | Start minikube cluster with podman driver (4GB RAM, 2 CPUs) |
| `make minikube-stop` | Stop minikube cluster |
| `make minikube-delete` | Delete minikube cluster completely |
| `make minikube-status` | Show minikube cluster status |
| `make minikube-dashboard` | Open Kubernetes dashboard in browser |
| `make minikube-dashboard-url` | Display dashboard URL |
| `make minikube-addons` | Enable metrics-server and dashboard addons |

### MinIO (Local S3 Testing)

| Command | Description |
|---------|-------------|
| `make minio-start` | Start MinIO container for S3 backup testing |
| `make minio-stop` | Stop MinIO container |
| `make minio-remove` | Remove MinIO container and data |
| `make minio-status` | Check MinIO status |
| `make minio-logs` | Show MinIO logs |
| `make list-backups-minio` | List backups stored in MinIO |

### Chart Development

| Command | Description |
|---------|-------------|
| `make lint` | Validate Helm chart syntax |
| `make package` | Package the chart into a .tgz file |
| `make template` | Generate Kubernetes manifests without deploying |

### Deployment

| Command | Description |
|---------|-------------|
| `make deploy` | Deploy with default values |
| `make deploy-replication` | Deploy with 1 primary + 2 replicas |
| `make deploy-with-backup` | Deploy with replication and hourly S3 backups to MinIO |
| `make full-deploy` | Complete workflow: start minikube → deploy → show status |
| `make full-deploy-replication` | Complete workflow with replication enabled |

### Management

| Command | Description |
|---------|-------------|
| `make uninstall` | Uninstall the Helm release |
| `make clean` | Uninstall and delete PVCs |
| `make status` | Show deployment status (pods, services, PVCs) |

### Database Operations

| Command | Description |
|---------|-------------|
| `make get-password` | Retrieve PostgreSQL password |
| `make connect` | Connect to PostgreSQL using psql |
| `make port-forward` | Forward PostgreSQL to localhost:5432 |
| `make shell` | Open bash shell in primary pod |

### Backup Operations

| Command | Description |
|---------|-------------|
| `make trigger-backup` | Manually trigger a backup job |
| `make check-backups` | Check backup CronJob and recent jobs |
| `make backup-logs` | Show logs from most recent backup job |

### Monitoring

| Command | Description |
|---------|-------------|
| `make logs` | Show last 50 lines of primary pod logs |
| `make logs-follow` | Follow primary pod logs in real-time |
| `make logs-replica` | Show replica pod logs (if exists) |
| `make watch` | Watch pod status in real-time |
| `make describe-pod` | Describe primary pod (useful for debugging) |

### Replication

| Command | Description |
|---------|-------------|
| `make check-replication` | Check replication status on primary and replicas |

### Testing Workflows

| Command | Description |
|---------|-------------|
| `make quick-test` | Run lint → package → deploy |
| `make reset` | Delete and recreate minikube cluster |

## Usage Examples

### Example 1: Basic Development Workflow

```bash
# Start fresh
make minikube-start

# Lint and package the chart
make lint
make package

# Deploy
make deploy

# Check status
make status

# View logs
make logs

# Connect to database
make connect

# Clean up when done
make clean
```

### Example 2: Testing with Replication

```bash
# Deploy with replication
make full-deploy-replication

# Wait for all pods to be ready
make watch
# Press Ctrl+C when all pods are Running

# Check replication status
make check-replication

# View primary logs
make logs

# View replica logs
make logs-replica

# Connect and test reads
make connect
```

### Example 3: Testing S3 Backups with MinIO

```bash
# Start MinIO for local S3 testing
make minio-start

# Deploy PostgreSQL with backups enabled
make deploy-with-backup

# Wait for deployment
make watch

# Check backup CronJob configuration
make check-backups

# Trigger a manual backup
make trigger-backup

# Wait a minute for backup to complete, then check logs
make backup-logs

# List backups in MinIO
make list-backups-minio

# Access MinIO console
# Open http://localhost:9001 in browser
# Username: minioadmin
# Password: minioadmin

# Clean up
make clean
make minio-remove
```

### Example 4: Port Forwarding for External Tools

```bash
# Start port forwarding
make port-forward

# In another terminal, connect using local psql or GUI tools
psql -h localhost -U postgres -d postgres

# Or use a database GUI like DBeaver, pgAdmin, etc.
# Host: localhost
# Port: 5432
# User: postgres
# Password: (get with 'make get-password')
```

### Example 5: Complete Reset

```bash
# If something goes wrong, reset everything
make reset

# This will:
# 1. Delete the minikube cluster
# 2. Start a fresh minikube cluster
```

## Configuration

The Makefile uses these default values (can be modified at the top of the Makefile):

```makefile
CHART_NAME := save-the-elephant
RELEASE_NAME := metadb
NAMESPACE := default
MINIKUBE_PROFILE := minikube
MINIKUBE_MEMORY := 4096
MINIKUBE_CPUS := 2
```

### MinIO Configuration

```makefile
MINIO_CONTAINER := minio-local
MINIO_PORT := 9000
MINIO_CONSOLE_PORT := 9001
MINIO_ACCESS_KEY := minioadmin
MINIO_SECRET_KEY := minioadmin
MINIO_BUCKET := postgres-backups
```

## Troubleshooting

### Minikube Won't Start

```bash
# Check Podman is working
podman ps

# If you see volume conflicts
make minikube-delete
podman volume prune

make minikube-start
```

### Podman Volume Issues

```bash
# Clean up podman volumes
podman volume prune

# Or remove specific volume
podman volume rm minikube
```

### MinIO Not Accessible from Pods

```bash
# Check MinIO is running
make minio-status

# Check MinIO logs
make minio-logs

# Restart MinIO
make minio-stop
make minio-start
```

### Backup Jobs Failing

```bash
# Check backup job logs
make backup-logs

# Check MinIO connectivity
make minio-status

# Verify S3 credentials in deployment
kubectl get secret metadb-save-the-elephant-s3 -n default -o yaml
```

### Pods Stuck in Pending

```bash
# Check pod events
make describe-pod

# Common issues:
# - Insufficient resources: Increase minikube memory
# - PVC binding issues: Check storage class
minikube start -p minikube --memory=8192 --driver=podman
```

### Deployment Fails

```bash
# Check Helm release
helm list -n default

# View logs
make logs

# Describe pod for events
make describe-pod

# Check if there are any errors in the chart
make lint
```

### Can't Connect to Database

```bash
# Verify pods are running
make status

# Check pod logs
make logs

# Verify service endpoints
kubectl get endpoints -n default

# Try port-forward instead
make port-forward
```

### Replication Not Working

```bash
# Check all pods are running
make status

# Check replication status
make check-replication

# View primary logs
make logs

# View replica logs
make logs-replica

# Check if replica can reach primary
kubectl exec metadb-save-the-elephant-postgresql-1 -n default -- \
  pg_isready -h metadb-save-the-elephant-postgresql-0.metadb-save-the-elephant-postgresql-headless
```

## Kubernetes Dashboard

The Makefile includes commands to easily access the Kubernetes dashboard for visual monitoring.

### Starting the Dashboard

**Option 1: Open in Browser (Recommended)**
```bash
make minikube-dashboard
```

This will:
- Ensure you're using the correct minikube profile
- Start the dashboard proxy
- Automatically open the dashboard in your default browser

**Note**: Keep the terminal running. Press `Ctrl+C` to stop the dashboard when done.

**Option 2: Get URL Only**
```bash
make minikube-dashboard-url
```

This displays the URL so you can copy/paste it into your browser manually.

### Enable Dashboard Features

To enable metrics (CPU/memory usage):
```bash
make minikube-addons
```

This enables:
- `metrics-server` - Required for CPU/memory metrics
- `dashboard` - The dashboard itself

### Using the Dashboard

Once open, you can:

**View Pods**
1. Click **Workloads** → **Pods**
2. See all PostgreSQL pods with their status
3. Click on a pod to view details, logs, or open a shell

**View Services**
1. Click **Service** → **Services**
2. Find your PostgreSQL services (primary, readonly, headless)

**View Persistent Volumes**
1. Click **Config and Storage** → **Persistent Volume Claims**
2. See PVCs for each PostgreSQL pod

**View Logs**
1. Navigate to **Workloads** → **Pods**
2. Click on a pod
3. Click the **Logs** icon (top right)

**Execute Shell**
1. Navigate to **Workloads** → **Pods**
2. Click on a pod
3. Click the **Exec** icon (terminal icon, top right)

Alternatively, use: `make shell`

### Dashboard vs Make Commands

| Task | Dashboard | Make Command |
|------|-----------|--------------|
| View pod logs | Pods → Click pod → Logs | `make logs` |
| Shell access | Pods → Click pod → Exec | `make shell` |
| View status | Multiple pages | `make status` |
| Get password | Secrets → Decode base64 | `make get-password` |
| Connect to DB | Copy info, use tool | `make connect` |

## Tips and Best Practices

1. **Use `make help`** - Always available reference for commands

2. **Use `make status`** - Quick overview of deployment state

3. **Use `make watch`** - Monitor pod state during deployments

4. **Use `make logs-follow`** - Debug issues in real-time

5. **Test backups locally** - Use MinIO to test S3 backup functionality before production

6. **Resource limits** - Adjust MINIKUBE_MEMORY if you need more resources

7. **Multiple terminals** - Use one for logs, one for commands

8. **Port forwarding** - Use `make port-forward` for GUI database tools

9. **Clean podman volumes** - If you encounter volume issues, run `podman volume prune`

## Next Steps

- Review [README.md](README.md) for detailed chart documentation
- Check [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines
- Explore [examples/](examples/) for configuration templates

## Support

If you encounter issues:
1. Run `make status` and `make logs`
2. Use `make describe-pod` for detailed pod information
3. Open an issue with the output from above commands
