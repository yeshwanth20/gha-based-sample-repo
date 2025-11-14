{{ define "workbench.externalSecret" }}
{{- if eq (include "workbench.containsAnySecrets" .) "true" -}}
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ include "workbench.serviceName" . }}
  annotations:
    {{- include "workbench.versionAnnotations" . | nindent 4 }}
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
    {{- include "workbench.timestampAnnotations" . | nindent 4 }}
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
spec:
  # We'd like to create/change the secret only during release or manually e.g. changing the annotations
  # using 0 used to work, but that behavior was changed - see https://github.com/external-secrets/external-secrets/issues/4167#issuecomment-2578881909
  refreshInterval: "10000h"
  secretStoreRef:
    name: {{ include "workbench.vaultExternalSecretStore" . }}
    kind: ClusterSecretStore
  target:
    name: {{ include "workbench.serviceName" . }}
  data:
    {{- $vaultPath := include "workbench.vaultServicePath" . }}
    {{- range .Values.vaultSecrets }}
    - secretKey: {{ . }}
      remoteRef:
        key: {{ $vaultPath }}
        property: {{ . }}
    {{- end }}
    {{- if .Values.splunk.enabled }}
    {{- $splunkVaultPath := include "workbench.vaultSplunkPath" . }}
    - secretKey: "splunk_password"
      remoteRef:
        key: {{ $splunkVaultPath }}
        property: "splunk_password"
    - secretKey: "inputs.conf"
      remoteRef:
        key: {{ $splunkVaultPath }}
        property: "inputs.conf"
    - secretKey: "outputs.conf"
      remoteRef:
        key: {{ $splunkVaultPath }}
        property: "outputs.conf"
    - secretKey: "props.conf"
      remoteRef:
        key: {{ $splunkVaultPath }}
        property: "props.conf"
    {{- end }}
{{- end -}}
{{- end -}}
