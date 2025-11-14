{{ define "workbench.configMap" }}
{{- if eq (include "workbench.containsAnyConfigs" .) "true" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "workbench.serviceName" . }}
  annotations:
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
data:
  {{- if .Values.configuration.default }}
    {{- .Values.configuration.default | toYaml | nindent 2 }}
  {{- end }}
  {{- if .Values.configuration.envSpecific }}
    {{- .Values.configuration.envSpecific | toYaml | nindent 2 }}
  {{- end }}
{{- end -}}
{{- end -}}
