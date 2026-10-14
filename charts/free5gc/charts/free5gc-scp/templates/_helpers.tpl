{{- define "free5gc-scp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "free5gc-scp.fullname" -}}
{{- if .Values.fullnameOverride }}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- else }}{{- $name := default .Chart.Name .Values.nameOverride }}{{- if contains $name .Release.Name }}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{- else }}{{ printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}{{- end }}{{- end }}
{{- end }}
{{- define "free5gc-scp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "free5gc-scp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "free5gc-scp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- define "free5gc-scp.labels" -}}
helm.sh/chart: {{ include "free5gc-scp.chart" . }}
{{ include "free5gc-scp.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
