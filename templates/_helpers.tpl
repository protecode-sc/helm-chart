{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "bdba.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bdba.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bdba.postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bdba.postgresql.passwordSecretName" -}}
    {{- if .Values.global.postgresql.existingSecret -}}
        {{- printf "%s" .Values.global.postgresql.existingSecret -}}
    {{- else -}}
        {{- printf "%s" (include "bdba.postgresql.fullname" .) -}}
    {{- end -}}
{{- end -}}

{{- define "bdba.minio.secretName" -}}
    {{- if .Values.minio.existingSecret -}}
        {{- printf "%s" .Values.minio.existingSecret -}}
    {{- else -}}
        {{- printf "%s" (include "bdba.minio.fullname" .) -}}
    {{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bdba.minio.fullname" -}}
{{- printf "%s-%s" .Release.Name "minio" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bdba.fluentd.fullname" -}}
{{- printf "%s-%s" .Release.Name "fluentd" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create django secret key
*/}}
{{- define "bdba.generated.djangoSecretKey" -}}
  {{- randAlphaNum 50 -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bdba.rabbitmq.fullname" -}}
{{- printf "%s-%s" .Release.Name "rabbitmq" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bdba.rabbitmq.brokerUrl" -}}
{{ $rabbithost := include "bdba.rabbitmq.fullname" . }}
{{- printf "amqp://%s:%%s@%s/" .Values.rabbitmq.rabbitmq.username $rabbithost }}
{{- end -}}

{{- define "bdba.rabbitmq.passwordSecretName" -}}
    {{- if .Values.rabbitmq.rabbitmq.existingPasswordSecret -}}
        {{- printf "%s" .Values.rabbitmq.rabbitmq.existingPasswordSecret -}}
    {{- else -}}
        {{- printf "%s" (include "bdba.rabbitmq.fullname" .) -}}
    {{- end -}}
{{- end -}}

{{- define "bdba.rabbitmq.erlangSecretName" -}}
    {{- if .Values.rabbitmq.rabbitmq.existingErlangSecret -}}
        {{- printf "%s" .Values.rabbitmq.rabbitmq.existingErlangSecret -}}
    {{- else -}}
        {{- printf "%s" (include "bdba.rabbitmq.fullname" .) -}}
    {{- end -}}
{{- end -}}

{{- define "bdba.configchecksum" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap-user.yaml") . | sha256sum }}
checksum/secrets: {{ include (print $.Template.BasePath "/secrets-user.yaml") . | sha256sum }}
{{- end }}

{{- define "bdba.s3endpoint" -}}
  {{- if .Values.minio.enabled -}}
    {{- printf "http://%s:%s" ( include "bdba.minio.fullname" . ) .Values.minio.service.port -}}
  {{- else -}}
    {{- printf "%s" .Values.s3Endpoint -}}
  {{- end -}}
{{- end -}}

{{- define "bdba.frontendenv" }}
envFrom:
  - configMapRef:
      name: {{ include "bdba.fullname" . }}-services-configmap
  - configMapRef:
      name: {{ include "bdba.fullname" . }}-user-configmap
  - secretRef:
      name: {{ include "bdba.fullname" . }}-user-secrets
  {{- if not .Values.minio.enabled }}
  - secretRef:
      name: {{ include "bdba.fullname" . }}-s3-secrets
  {{- end }}
  - secretRef:
      {{- if .Values.frontend.web.djangoSecretKey }}
      name: {{ include "bdba.fullname" . }}-django-secrets
      {{- else }}
      name: {{ include "bdba.fullname" . }}-django-secrets-generated
      {{- end }}
  {{- if not .Values.postgresql.enabled }}
  - secretRef:
      name: {{ include "bdba.fullname" . }}-postgresql-secrets
  {{- end }}
env:
  - name: BROKER_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "bdba.rabbitmq.passwordSecretName" . }}
        key: rabbitmq-password
  {{- if and .Values.postgresql.enabled }}
  - name: PGPASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "bdba.postgresql.passwordSecretName" . }}
        key: postgresql-password
  {{- end }}
  {{- if .Values.minio.enabled }}
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: {{ include "bdba.minio.secretName" . }}
        key: accesskey
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: {{ include "bdba.minio.secretName" . }}
        key: secretkey
{{- end }}
{{- end }}

{{- define "bdba.s3env" -}}
{{- if or (.Values.s3Endpoint) (.Values.minio.enabled) }}
- name: S3_ENDPOINT
  valueFrom:
    configMapKeyRef:
      name: {{ include "bdba.fullname" . }}-services-configmap
      key: S3_ENDPOINT
{{- end }}
{{- if .Values.minio.enabled }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "bdba.minio.secretName" . }}
      key: accesskey
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "bdba.minio.secretName" . }}
      key: secretkey
{{- else }}
{{- if .Values.s3AccessKeyId }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "bdba.fullname" . }}-s3-secrets
      key: AWS_ACCESS_KEY_ID
{{- end }}
{{- if .Values.s3SecretAccessKey }}
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "bdba.fullname" . }}-s3-secrets
      key: AWS_SECRET_ACCESS_KEY
{{- end }}
{{- end }}
{{- end -}}


{{- define "bdba.frontendmounts" -}}
{{- if .Values.rootCASecret }}
- name: ca-store
  mountPath: /usr/local/share/ca-certificates/appcheck/
  readOnly: true
{{- end }}
{{- if .Values.frontend.ldap.rootCASecret }}
- name: ldapca-store
  mountPath: /ldap/ssl/
  readOnly: true
{{- end }}
{{- if .Values.frontend.database.clientSecretName }}
- name: pgssl-client-store
  mountPath: /postgresql/client-cert/
  readOnly: true
{{- end }}
{{- if .Values.frontend.database.rootCASecretName }}
- name: pgssl-ca-store
  mountPath: /postgresql/ca/
  readOnly: true
{{- end }}
- name: tmpdir
  mountPath: /tmp
{{- end -}}

{{- define "bdba.frontendvolumes" -}}
{{- if .Values.rootCASecret }}
- name: ca-store
  secret:
    secretName: {{ .Values.rootCASecret }}
{{- end }}
{{- if .Values.frontend.ldap.rootCASecret }}
- name: ldapca-store
  secret:
    secretName: {{ .Values.frontend.ldap.rootCASecret }}
{{- end }}
{{- if .Values.frontend.database.clientSecretName }}
- name: pgssl-client-store
  secret:
    secretName: {{ .Values.frontend.database.clientSecretName }}
{{- end }}
{{- if .Values.frontend.database.rootCASecretName }}
- name: pgssl-ca-store
  secret:
    secretName: {{ .Values.frontend.database.rootCASecretName }}
{{- end }}
- name: tmpdir
  emptyDir: {}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bdba.memcached.fullname" -}}
{{- printf "%s-%s" .Release.Name "memcached" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bdba.webapp.fullname" -}}
{{- printf "%s-%s" .Release.Name "webapp" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bdba.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create release name and version as used by the chart label.
*/}}
{{- define "bdba.releaseversion" -}}
{{ $fullname := include "bdba.fullname" . }}
{{- printf "%s-%s" $fullname .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "bdba.labels" -}}
app.kubernetes.io/name: {{ include "bdba.name" . }}
helm.sh/chart: {{ include "bdba.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

