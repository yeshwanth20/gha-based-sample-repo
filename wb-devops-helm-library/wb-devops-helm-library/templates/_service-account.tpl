{{ define "workbench.serviceAccount" }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "workbench.serviceAccountName" . }}
  annotations:
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
automountServiceAccountToken: true
{{- end }}
