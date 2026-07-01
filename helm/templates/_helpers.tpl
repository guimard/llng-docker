{{/*
Expand the name of the chart.
*/}}
{{- define "lemonldap.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lemonldap.fullname" -}}
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
{{- define "lemonldap.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lemonldap.labels" -}}
helm.sh/chart: {{ include "lemonldap.chart" . }}
{{ include "lemonldap.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lemonldap.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lemonldap.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lemonldap.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lemonldap.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Contruct standard format for Postgres connection URI:
*/}}
{{- define "postgres.url" -}}
  {{- $host := .Values.config.postgres.host }}
  {{- $port := .Values.config.postgres.port | toString }}
  {{- $sslMode := .Values.config.postgres.sslMode }}
  {{- $dbName := .Values.config.postgres.dbName }}
  {{- printf "DBI:Pg:database=%s;host=%s;port=%s;sslmode=%s" $dbName $host $port $sslMode }}
{{- end -}}