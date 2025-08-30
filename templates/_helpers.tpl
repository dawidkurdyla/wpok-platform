{{/*
Copyright © 2025

Helper templates for the WPOK chart. These functions construct stable
names and URLs without depending on internal helpers of subcharts.
*/}}

{{/*
Return the canonical name for the release. If fullnameOverride is provided
it is used; otherwise the release name is suffixed with the chart name.
*/}}
{{- define "wpok.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Kubernetes cluster domain. Can be overridden via .Values.clusterDomain.
Defaults to "cluster.local".
*/}}
{{- define "wpok.clusterDomain" -}}
{{- default "cluster.local" .Values.clusterDomain -}}
{{- end -}}

{{/*
Return the RabbitMQ service name in this release.
If the rabbitmq subchart defines fullnameOverride, respect it; otherwise
use the conventional "<release>-rabbitmq".
This avoids depending on the subchart's internal "rabbitmq.fullname" helper.
*/}}
{{- define "wpok.rabbitmqServiceName" -}}
{{- if .Values.rabbitmq.fullnameOverride -}}
{{- .Values.rabbitmq.fullnameOverride -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "rabbitmq" -}}
{{- end -}}
{{- end -}}

{{/*
Return the fully-qualified DNS hostname for RabbitMQ.
When the rabbitmq subchart is enabled, compose the FQDN using the service
name and the release namespace. When disabled, fall back to a conventional
"rabbitmq.<namespace>.svc.<clusterDomain>" so the operator can still target
an existing broker in the cluster (or be overridden via wpokOperator.rabbitApi.overrideUrl).
*/}}
{{- define "wpok.rabbitmqHost" -}}
{{- $ns := .Release.Namespace -}}
{{- $domain := include "wpok.clusterDomain" . -}}
{{- if .Values.rabbitmq.enabled -}}
{{- printf "%s.%s.svc.%s" (include "wpok.rabbitmqServiceName" .) $ns $domain -}}
{{- else -}}
{{- printf "rabbitmq.%s.svc.%s" $ns $domain -}}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ Management API URL.
If wpokOperator.rabbitApi.overrideUrl is set, use it verbatim.
Otherwise construct "http://<host>:15672/api" where <host> comes from
"wpok.rabbitmqHost". Note: the AMQP vhost is NOT a part of the HTTP URL;
it is used within API payloads/auth, not in the path.
*/}}
{{- define "wpok.rabbitmqApiUrl" -}}
{{- $override := .Values.wpokOperator.rabbitApi.overrideUrl | default "" -}}
{{- if ne $override "" -}}
{{- $override -}}
{{- else -}}
{{- printf "http://%s:15672/api" (include "wpok.rabbitmqHost" .) -}}
{{- end -}}
{{- end -}}
