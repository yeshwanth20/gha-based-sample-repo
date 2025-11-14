{{- define "workbench.hpa" -}}
{{- if hasKey .Values.hpa "enabled" | ternary .Values.hpa.enabled true }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "workbench.serviceName" . }}-hpa
  annotations:
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "workbench.serviceName" . }}
  minReplicas: {{ .Values.hpa.minReplicas }}
  maxReplicas: {{ .Values.hpa.maxReplicas }}
  metrics:
  {{- if .Values.hpa.cpuPercentage }}
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.hpa.cpuPercentage }}
  {{- end }}
  {{- if not .Values.hpa.useSimpleHpa }}
  {{- if .Values.hpa.tpsValue }}
  - type: Pods
    pods:
      metric:
        name: http_server_requests_per_second
      target:
        type: AverageValue
        averageValue: {{ .Values.hpa.tpsValue | quote }}
  {{- end }}
  {{- if .Values.hpa.memoryPercentage }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ .Values.hpa.memoryPercentage }}
  {{- end }}
  {{- end }}
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      selectPolicy: Max
      policies:
      - type: Pods
        value: 1
        periodSeconds: 180
    scaleDown:
      stabilizationWindowSeconds: 300
      selectPolicy: Max
      policies:
      - type: Pods
        value: 1
        periodSeconds: 300
{{- end -}}
{{- end -}}
