{{ define "workbench.ingress" }}
{{ $serviceName := include "workbench.serviceName" . }}
{{ $ingressUrls := include "workbench.ingressUrls" . | split "," }}
{{ $ingressPath := include "workbench.ingressPath" . }}
{{ $ingressPathType := include "workbench.ingressPathType" . }}
{{ $servicePort := include "workbench.servicePort" . }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $serviceName }}-ingress
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
  annotations:
    {{- include "workbench.ingressAnnotations" . | nindent 4 }}
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
spec:
  ingressClassName: {{ include "workbench.ingressClassName" . }}
  tls:
    - hosts: 
      {{- range $url := $ingressUrls }}
      - {{ $url }}
      {{- end }}
      secretName: {{ include "workbench.ingressSecretName" . }}
  rules:
    {{- range $url := $ingressUrls }}
    - host: {{ $url }}
      http:
        paths:
          - path: {{ $ingressPath }}
            pathType: {{ $ingressPathType }}
            backend:
              service:
                name: {{ $serviceName | quote }}
                port:
                  number: {{ $servicePort }}
    {{- end }}
{{- end }}
