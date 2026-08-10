{{/*
Expand the name of the chart.
*/}}
{{- define "banking-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Full image reference helper.
*/}}
{{- define "banking-app.image" -}}
{{- $registry := .registry -}}
{{- $repo := .repository -}}
{{- $tag := .tag -}}
{{- printf "%s/%s:%s" $registry $repo $tag }}
{{- end }}

{{/*
Namespace helper.
*/}}
{{- define "banking-app.namespace" -}}
{{- printf "banking-%s" .Values.environment }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "banking-app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
environment: {{ .Values.environment }}
{{- end }}