{{- define "workbench.serviceMonitor" }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "workbench.serviceName" . }}-svc-monitor
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
  annotations:
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
spec:
  endpoints:
  - interval: 10s
    path: /actuator/http.server.requests.count
    port: {{ include "workbench.serviceName" . }}-port
  selector:
    matchLabels:
      service: {{ include "workbench.serviceName" . }}
  fallbackScrapeProtocol: PrometheusText1.0.0
{{- end }}
