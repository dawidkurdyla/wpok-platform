{{/*
Copyright © 2025

This file contains helper templates for the WPOK chart.  Helper
functions simplify the construction of names and references for subcharts
and services.
*/}}

{{/*
Return the canonical name for the release.  This replicates the pattern
used by the upstream hyperflow-worker-pool-operator chart.  If a
fullnameOverride is provided in values.yaml it is used; otherwise the
release name is suffixed with the chart name.
*/}}
{{- define "wpok.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Return the service hostname for RabbitMQ.  When the rabbitmq subchart
is enabled we defer to its fullname template.  Otherwise we assume a
service named "rabbitmq" exists in the release namespace.
*/}}
{{- define "wpok.rabbitmqHost" -}}
{{- if .Values.rabbitmq.enabled -}}
{{ include "rabbitmq.fullname" (dict "Chart" (dict) "Release" .Release "Values" (dict)) }}
{{- else -}}
rabbitmq
{{- end -}}
{{- end -}}

{{/*
Return the API URL for RabbitMQ.  If overrideUrl is provided in
wpokOperator.rabbitApi it is used.  Otherwise construct the URL using
the rabbitmq host and vhost from values.
*/}}
{{- define "wpok.rabbitmqApiUrl" -}}
{{- $override := .Values.wpokOperator.rabbitApi.overrideUrl -}}
{{- if and $override (ne $override "") -}}
{{- $override -}}
{{- else -}}
{{- $host := include "wpok.rabbitmqHost" . -}}
{{- $vhost := .Values.wpokOperator.rabbitApi.vhost | urlquery -}}
http://{{ $host }}:15672/api
{{- end -}}
{{- end -}}