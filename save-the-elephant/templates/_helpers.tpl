{{/*
Expand the name of the chart.
*/}}
{{- define "save-the-elephant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "save-the-elephant.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "save-the-elephant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "save-the-elephant.labels" -}}
helm.sh/chart: {{ include "save-the-elephant.chart" . }}
{{ include "save-the-elephant.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "save-the-elephant.selectorLabels" -}}
app.kubernetes.io/name: {{ include "save-the-elephant.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "save-the-elephant.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "save-the-elephant.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate PostgreSQL password
*/}}
{{- define "save-the-elephant.postgresPassword" -}}
{{- if .Values.postgresql.auth.existingSecret }}
{{- printf "%s" .Values.postgresql.auth.existingSecret }}
{{- else if .Values.postgresql.auth.password }}
{{- printf "%s" .Values.postgresql.auth.password }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}

{{/*
Generate replication password
*/}}
{{- define "save-the-elephant.replicationPassword" -}}
{{- if .Values.postgresql.auth.existingSecret }}
{{- printf "%s" .Values.postgresql.auth.existingSecret }}
{{- else if .Values.postgresql.auth.replicationPassword }}
{{- printf "%s" .Values.postgresql.auth.replicationPassword }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}

{{/*
Get the secret name for PostgreSQL credentials
*/}}
{{- define "save-the-elephant.secretName" -}}
{{- if .Values.postgresql.auth.existingSecret }}
{{- printf "%s" .Values.postgresql.auth.existingSecret }}
{{- else }}
{{- printf "%s-postgresql" (include "save-the-elephant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get the secret name for S3 credentials
*/}}
{{- define "save-the-elephant.s3SecretName" -}}
{{- if .Values.backup.s3.existingSecret }}
{{- printf "%s" .Values.backup.s3.existingSecret }}
{{- else }}
{{- printf "%s-s3" (include "save-the-elephant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Shared backup container env vars (all except POSTGRES_DATABASE, which varies per container).
Caller must supply root context — pass $ inside range, . outside.
*/}}
{{- define "save-the-elephant.backupContainerEnv" -}}
# S3 Configuration
- name: S3_REGION
  value: {{ .Values.backup.s3.region | quote }}
- name: S3_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "save-the-elephant.s3SecretName" . }}
      key: access-key-id
- name: S3_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "save-the-elephant.s3SecretName" . }}
      key: secret-access-key
- name: S3_BUCKET
  value: {{ .Values.backup.s3.bucket | quote }}
{{- if .Values.backup.s3.endpoint }}
- name: S3_ENDPOINT
  valueFrom:
    secretKeyRef:
      name: {{ include "save-the-elephant.s3SecretName" . }}
      key: endpoint
{{- end }}
{{- if .Values.backup.s3.prefix }}
- name: S3_PREFIX
  value: {{ .Values.backup.s3.prefix | quote }}
{{- else }}
- name: S3_PREFIX
  value: "release={{ .Release.Name }}/namespace={{ .Release.Namespace }}"
{{- end }}
# PostgreSQL Configuration
{{- if .Values.replication.enabled }}
- name: POSTGRES_HOST
  value: "{{ include "save-the-elephant.fullname" . }}-postgresql-0.{{ include "save-the-elephant.fullname" . }}-postgresql-headless.{{ .Release.Namespace }}.svc.cluster.local"
{{- else }}
- name: POSTGRES_HOST
  value: "{{ include "save-the-elephant.fullname" . }}-postgresql.{{ .Release.Namespace }}.svc.cluster.local"
{{- end }}
- name: POSTGRES_USER
  value: {{ .Values.postgresql.auth.username | quote }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "save-the-elephant.secretName" . }}
      key: postgres-password
{{- end }}

{{/*
Primary selector labels
*/}}
{{- define "save-the-elephant.primarySelectorLabels" -}}
{{ include "save-the-elephant.selectorLabels" . }}
app.kubernetes.io/component: primary
{{- end }}

{{/*
Replica selector labels
*/}}
{{- define "save-the-elephant.replicaSelectorLabels" -}}
{{ include "save-the-elephant.selectorLabels" . }}
app.kubernetes.io/component: replica
{{- end }}
