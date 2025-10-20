# Save The Elephant - PostgreSQL Helm Chart

A lightweight non CRD dependent production-ready PostgreSQL Helm chart with S3 backup capabilities and optional streaming replication support.

## Features

- **PostgreSQL 17.4** - Latest stable version of PostgreSQL
- **S3 Backups** - Automated backups to S3-compatible storage (retention managed via S3 lifecycle policies)
- **Streaming Replication** - Optional read replicas with automatic data replication
- **High Availability** - StatefulSet-based deployment with persistent storage
- **Security** - Configurable security contexts and secret management
- **Customizable** - Extensive configuration options for production use

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Persistent Volume provisioner support in the underlying infrastructure
- S3-compatible storage and credentials (for backups)

## Getting Started

### Local Development

For local development and testing with Minikube, this project includes a comprehensive Makefile. See [MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md) for full instructions on all available commands.

```bash
# Quick start: Deploy PostgreSQL locally
make full-deploy

# Deploy with replication
make full-deploy-replication

# Deploy with S3 backups to local MinIO
make deploy-with-backup
```

### Kubernetes Deployment

#### Basic Installation (Single Instance)

```bash
helm install my-postgres ./save-the-elephant \
  --set postgresql.auth.password=changeme123
```

#### With Replication (1 Primary + 2 Replicas)

```bash
helm install my-postgres ./save-the-elephant \
  --set postgresql.auth.password=changeme123 \
  --set replication.enabled=true \
  --set replication.replicas=2
```

### Connect to PostgreSQL

```bash
# Get the password
export POSTGRES_PASSWORD=$(kubectl get secret my-postgres-save-the-elephant-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

# Connect from within the cluster
kubectl run my-postgres-client --rm --tty -i --restart='Never' \
  --image postgres:17.4 \
  --env="PGPASSWORD=$POSTGRES_PASSWORD" \
  --command -- psql -h my-postgres-save-the-elephant-postgresql -U postgres -d postgres

# Or use port-forward
kubectl port-forward svc/my-postgres-save-the-elephant-postgresql 5432:5432
psql -h localhost -U postgres -d postgres
```

## Configuration Examples

### Enable S3 Backups

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  s3:
    bucket: "my-postgres-backups"
    region: "us-east-1"
    accessKeyId: "YOUR_ACCESS_KEY"
    secretAccessKey: "YOUR_SECRET_KEY"
```

**Note:** Backup retention is managed via S3 bucket lifecycle policies, not within the Helm chart. Configure your S3 bucket with lifecycle rules to automatically expire old backups.

### Enable Replication

```yaml
replication:
  enabled: true
  replicas: 2
  synchronousCommit: "off"
```

### Custom Resources

```yaml
postgresql:
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
    requests:
      cpu: 1000m
      memory: 2Gi
  persistence:
    size: 50Gi
```

## Using as a Subchart

Add to your `Chart.yaml`:

```yaml
dependencies:
  - name: save-the-elephant
    version: "0.1.0"
    repository: "https://rarup1.github.io/save-the-elephant"
```

Configure in your `values.yaml`:

```yaml
save-the-elephant:
  postgresql:
    auth:
      password: "mypassword"
      database: "myapp"
  replication:
    enabled: true
    replicas: 1
```

## Service Access

When deployed, the chart creates the following services:

- **Primary Service** (read-write): `<release-name>-save-the-elephant-postgresql`
- **Read-only Service** (replicas): `<release-name>-save-the-elephant-postgresql-readonly`
- **Headless Service** (StatefulSet DNS): `<release-name>-save-the-elephant-postgresql-headless`

## Common Operations

### Trigger Manual Backup

```bash
kubectl create job --from=cronjob/my-postgres-save-the-elephant-backup manual-backup-$(date +%s)
```

### Check Replication Status

```bash
# On primary
kubectl exec my-postgres-save-the-elephant-postgresql-0 -- \
  psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# On replica
kubectl exec my-postgres-save-the-elephant-postgresql-1 -- \
  psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"
```

### Upgrade Chart

```bash
helm upgrade my-postgres ./save-the-elephant -f my-values.yaml
```

### Uninstall

```bash
# Uninstall release
helm uninstall my-postgres

# Delete PVCs (if needed)
kubectl delete pvc -l app.kubernetes.io/name=save-the-elephant
```

## Supported PostgreSQL Versions

| PostgreSQL Version | Docker Image Tag | Status | Notes |
|-------------------|------------------|---------|-------|
| 17.4 | `postgres:17.4` | ✅ Tested | Latest version, recommended |
| 17.x | `postgres:17` | ✅ Compatible | Latest PostgreSQL 17 |
| 16.x | `postgres:16` | ✅ Compatible | PostgreSQL 16 series |
| 15.x | `postgres:15` | ✅ Compatible | PostgreSQL 15 series |
| 14.x | `postgres:14` | ✅ Compatible | PostgreSQL 14 series |
| 13.x | `postgres:13` | ✅ Compatible | PostgreSQL 13 series |
| 12.x | `postgres:12` | ⚠️ Compatible | Older version, consider upgrading |

## Helm Chart Values

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.image.repository` | PostgreSQL image repository | `postgres` |
| `postgresql.image.tag` | PostgreSQL image tag | `17.4` |
| `postgresql.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `postgresql.auth.username` | PostgreSQL username | `postgres` |
| `postgresql.auth.password` | PostgreSQL password (auto-generated if empty) | `""` |
| `postgresql.auth.database` | Database name | `postgres` |
| `postgresql.auth.replicationUsername` | Replication username | `replicator` |
| `postgresql.auth.replicationPassword` | Replication password (auto-generated if empty) | `""` |
| `postgresql.auth.existingSecret` | Use existing secret for credentials | `""` |
| `postgresql.config.maxConnections` | Maximum connections | `"100"` |
| `postgresql.config.sharedBuffers` | Shared buffers | `"128MB"` |
| `postgresql.config.effectiveCacheSize` | Effective cache size | `"512MB"` |
| `postgresql.config.walLevel` | WAL level (must be 'replica' for replication) | `"replica"` |
| `postgresql.config.maxWalSenders` | Max WAL senders | `"10"` |
| `postgresql.config.walKeepSize` | WAL keep size | `"1GB"` |
| `postgresql.resources.limits.cpu` | CPU limit | `1000m` |
| `postgresql.resources.limits.memory` | Memory limit | `1Gi` |
| `postgresql.resources.requests.cpu` | CPU request | `250m` |
| `postgresql.resources.requests.memory` | Memory request | `256Mi` |
| `postgresql.persistence.enabled` | Enable persistence | `true` |
| `postgresql.persistence.storageClass` | Storage class | `""` |
| `postgresql.persistence.accessMode` | Access mode | `ReadWriteOnce` |
| `postgresql.persistence.size` | PVC size | `10Gi` |
| `postgresql.persistence.annotations` | PVC annotations | `{}` |

### Replication Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replication.enabled` | Enable PostgreSQL streaming replication | `false` |
| `replication.replicas` | Number of read replicas | `1` |
| `replication.synchronousCommit` | Sync mode: off/on/remote_write/remote_apply | `"off"` |
| `replication.resources` | Resources for replica pods (if different from primary) | `{}` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.primary.type` | Primary service type | `ClusterIP` |
| `service.primary.port` | Primary service port | `5432` |
| `service.primary.annotations` | Primary service annotations | `{}` |
| `service.readOnly.enabled` | Enable read-only service | `true` |
| `service.readOnly.type` | Read-only service type | `ClusterIP` |
| `service.readOnly.port` | Read-only service port | `5432` |
| `service.readOnly.annotations` | Read-only service annotations | `{}` |

### Backup Configuration

The backup image version automatically matches your PostgreSQL major version (e.g., PostgreSQL 17.4 uses backup image tag `17`, PostgreSQL 16.3 uses tag `16`). You can override this by setting `backup.image.tag` explicitly.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backup.enabled` | Enable S3 backups | `true` |
| `backup.schedule` | Cron schedule for backups | `"0 2 * * *"` |
| `backup.successfulJobsHistoryLimit` | Successful jobs to retain | `3` |
| `backup.failedJobsHistoryLimit` | Failed jobs to retain | `1` |
| `backup.ttlSecondsAfterFinished` | Time in seconds before completed jobs are deleted | `300` |
| `backup.s3.bucket` | S3 bucket name | `"postgres-backups"` |
| `backup.s3.region` | S3 region | `"us-east-1"` |
| `backup.s3.endpoint` | S3 endpoint (for MinIO, etc) | `""` |
| `backup.s3.prefix` | S3 path prefix (defaults to `release=<release-name>/namespace=<namespace>/` if empty) | `""` |
| `backup.s3.accessKeyId` | S3 access key ID | `""` |
| `backup.s3.secretAccessKey` | S3 secret access key | `""` |
| `backup.s3.existingSecret` | Use existing secret for S3 credentials | `""` |
| `backup.image.repository` | Backup job image | `rarup1/postgres-backup-s3` |
| `backup.image.tag` | Backup job image tag (auto-detects from PostgreSQL version if empty) | `""` |
| `backup.image.pullPolicy` | Backup image pull policy | `IfNotPresent` |
| `backup.resources.limits.cpu` | Backup job CPU limit | `500m` |
| `backup.resources.limits.memory` | Backup job memory limit | `512Mi` |
| `backup.resources.requests.cpu` | Backup job CPU request | `100m` |
| `backup.resources.requests.memory` | Backup job memory request | `128Mi` |

### Other Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `podAnnotations` | Pod annotations | `{}` |
| `podLabels` | Custom labels for pods | `{}` |
| `podSecurityContext.fsGroup` | Pod fsGroup | `999` |
| `securityContext.runAsUser` | Container runAsUser | `999` |
| `securityContext.runAsNonRoot` | Run as non-root | `true` |
| `securityContext.capabilities.drop` | Capabilities to drop | `["ALL"]` |
| `securityContext.readOnlyRootFilesystem` | Read-only root filesystem | `false` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |
| `initContainers` | Additional init containers | `[]` |
| `extraVolumes` | Additional volumes | `[]` |
| `extraVolumeMounts` | Additional volume mounts | `[]` |
| `extraEnv` | Additional environment variables | `[]` |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
