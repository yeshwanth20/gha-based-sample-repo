{{- define "workbench.deployment" }}
{{ $serviceName := include "workbench.serviceName" . }}
{{ $containerPort := include "workbench.containerPort" . }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $serviceName | quote }}
  labels:
    {{- include "workbench.commonLabels" . | nindent 4 }}
    {{- include "workbench.datadogDeployLabels" . | nindent 4 }}
  annotations:
    {{- include "workbench.versionAnnotations" . | nindent 4 }}
    {{- include "workbench.libraryVersionAnnotations" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicas }}
  strategy:
    {{- include "workbench.deploymentStrategy" . | nindent 4 }}
  selector:
    matchLabels:
      service: {{ $serviceName | quote }}
  template:
    metadata:
      annotations:
        {{- include "workbench.prometheusAnnotations" . | nindent 8 }}
        {{- include "workbench.versionAnnotations" . | nindent 8 }}
        {{- include "workbench.datadogAnnotations" . | nindent 8 }}
        {{- include "workbench.timestampAnnotations" . | nindent 8 }}
        {{- include "workbench.configHashAnnotations" . | nindent 8 }}
        {{- include "workbench.daprAnnotations" . | nindent 8 }}
      labels:
        {{- include "workbench.commonLabels" . | nindent 8 }}
        {{- include "workbench.datadogPodLabels" . | nindent 8 }}
    spec:
      {{- include "workbench.nodeConfiguration" . | nindent 6 }}
      {{- include "workbench.initContainers" . | nindent 6 }}
      # CS-5521 | Do not disable default seccomp
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      # CS-5059 | Do not share host process namespaces
      # Required for security scanning - false is default
      hostNetwork: false
      volumes:
        {{- include "workbench.volumes" . | nindent 8 }}
      containers:
      - image: {{ include "workbench.serviceImage" . | quote }}
        name: {{ $serviceName | quote }}
        ports:
        - containerPort: {{ $containerPort }}
        {{- if .Values.serviceContainerCommand }}
        command: 
          {{- toYaml .Values.serviceContainerCommand | nindent 10 }}
        {{- end }}
        {{- include "workbench.containerProbes" . | nindent 8 }}
        securityContext:
          # CS-5525 | Restrict container from acquiring additional privileges
          allowPrivilegeEscalation: false
          # CS-5512 | Mount container's root filesystem as read only
          # Also need writable volumes 'tmp' and 'logs' with volumeMounts '/tmp', '/logs'
          readOnlyRootFilesystem: true
          # CS-599 | Run with non-root user, defined in Dockerfile with uid 10001
          runAsNonRoot: true
          runAsUser: 10001
          # CS-5054 | Do not use privileged containers
          # Required for security scanning - false is default
          privileged: false
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        env:
          - name: BUILD_VER
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.annotations['workbench.pwc.com/service-version']
          - name: COMMIT_ID
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.annotations['workbench.pwc.com/service-commit-hash']
          - name: DEPLOY_INFO
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.annotations['workbench.pwc.com/deployment-timestamp']
          {{- include "workbench.datadogEnv" . | nindent 10 }}
          {{- include "workbench.dotnetPortEnv" . | nindent 10 }}
        {{- include "workbench.envFrom" . | nindent 8 }}  
        imagePullPolicy: Always
        volumeMounts:
          # CS-5512 | /tmp and /logs cannot be in root volume when readOnlyRootFilesystem: true
          {{- include "workbench.serviceContainerVolumeMounts" . | nindent 10 }}
      {{- include "workbench.splunkSidecar" . | nindent 6 }}
      {{- include "workbench.imagePullSecrets" . | nindent 6 }}
      {{- if (and .Values.serviceAccount .Values.serviceAccount.addToContainer) }}
      {{- $serviceName := include "workbench.serviceAccountName" . }}
      serviceAccountName: {{ $serviceName }}
      serviceAccount: {{ $serviceName }}
      {{- end }}
{{- end }}
