{{- define "workbench.service" }}
{{ $serviceName := include "workbench.serviceName" . }}
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceName | quote }}
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
  annotations:
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
spec:
  ports:
  - name: {{ $serviceName }}-port
    port: {{ include "workbench.servicePort" . }}
    targetPort: {{ include "workbench.containerPort" . }}
  selector:
    service: {{ $serviceName | quote }}
{{- end }}
