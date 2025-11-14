{{- define "workbench.serviceName" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "workbench.environment" -}}
{{ .Values.global.environment }}
{{- end }}

{{- define "workbench.valueStream" -}}
{{ .Values.general.valueStream }}
{{- end -}}

{{- define "workbench.region" -}}
{{ $parts := split "-" (include "workbench.environment" .) }}
{{- $parts._0 -}}
{{- end }}

{{- define "workbench.stage" -}}
{{ $parts := split "-" (include "workbench.environment" .) }}
{{- $parts._1 -}}
{{- end }}

{{/*
Common set of labels on the deployment - we might not need this
*/}}
{{ define "workbench.commonLabels" -}}
service: {{ include "workbench.serviceName" . | quote }}
team: {{ .Values.general.team | quote }}
env: {{ include "workbench.stage" . | quote }}
value_stream: {{ include "workbench.valueStream" . | quote }}
pwc_territory: {{ include "workbench.region" . | quote }}
pwc_ciid: {{ .Values.general.ciid }}
{{- end }}


{{/*
Common set of labels on the deployment - we might not need this
*/}}
{{ define "workbench.commonPostDeployLabels" -}}
team: {{ .Values.general.team | quote }}
env: {{ include "workbench.stage" . | quote }}
value_stream: {{ include "workbench.valueStream" . | quote }}
pwc_territory: {{ include "workbench.region" . | quote }}
pwc_ciid: {{ .Values.general.ciid }}
workbench.pwc.com/post-deploy-for-service: {{  include "workbench.serviceName" $ | quote }}
{{- end }}

{{/*
Common set of datadog-related labels on the deployment - we might not need this
*/}}
{{ define "workbench.datadogDeployLabels" -}}
tags.datadoghq.com/env: {{ (include "workbench.environment" .) }}-deploy
tags.datadoghq.com/service: {{ include "workbench.serviceName" . }}
tags.datadoghq.com/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Common set of datadog-related labels on the pod
*/}}
{{ define "workbench.datadogPodLabels" -}}
{{- include "workbench.datadogDeployLabels" . }}
{{- if or (eq .Values.general.language "dotnet") (eq .Values.general.language "node") }}
admission.datadoghq.com/enabled: "true"
{{- end -}}
{{- end }}

{{/*
Common set of datadog-related annotations on the deployment
*/}}
{{ define "workbench.datadogAnnotations" -}}
{{- $serviceName := include "workbench.serviceName" . -}}
{{- $valueStream := include "workbench.valueStream" . -}}
ad.datadoghq.com/tags: '{"values_stream": "{{ $valueStream }}"}'
{{ if (eq .Values.general.language "java") -}}
ad.datadoghq.com/{{ $serviceName }}.logs: |-
  [{
    "source": "{{ $serviceName }}",
    "service": "{{ $serviceName }}",
    "sourcecategory": "sourcecode"
  }]
{{- end -}}
{{ if (eq .Values.general.language "dotnet") }}
admission.datadoghq.com/dotnet-lib.version: "v2.31.0"
{{- end -}}
{{ if (eq .Values.general.language "node") }}
admission.datadoghq.com/js-lib.version: "v4.6.0" 
{{- end -}}
{{- end }}

{{/*
Building service image reference based on environment and overrides
*/}}
{{- define "workbench.serviceImage" }}
{{- $registry := (.Values.image).registry | default (include "workbench.imageRegistry" .) -}}
{{- $repository := (.Values.image).repository | default (include "workbench.imageRepository" .) -}}
{{- $ref := (.Values.image).tag | default .Chart.AppVersion -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s:%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s:%s" $registry $repository $ref -}}
{{- end -}}
{{- end -}}

{{/*
Building GIF update image reference based on environment and overrides
*/}}
{{- define "workbench.gifUpdateImage" }}
{{- $registry := (.Values.postDeployment.gifUpdate.image).registry | default (include "workbench.imageRegistry" .) -}}
{{- $repository := (.Values.postDeployment.gifUpdate.image).repository | default "wb-devops-gif-update" -}}
{{- $ref := (.Values.postDeployment.gifUpdate.image).tag | default "1.0.0" -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s:%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s:%s" $registry $repository $ref -}}
{{- end -}}
{{- end -}}

{{/*
Setting resources for gif update job based on values
*/}}
{{- define "workbench.gifUpdateResources" -}}
{{- if (((.Values.postDeployment).gifUpdate).resources) -}}
resources:
{{- toYaml .Values.postDeployment.gifUpdate.resources | nindent 2 }}
{{- else -}}
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
{{- end -}}
{{- end -}}

{{/*
Building SQL migration image reference based on environment and overrides
*/}}
{{- define "workbench.sqlMigrationImage" }}
{{- $registry := (.Values.postDeployment.sqlMigration.image).registry | default (include "workbench.imageRegistry" .) -}}
{{- $repository := (.Values.postDeployment.sqlMigration.image).repository | default (include "workbench.imageRepository" .) -}}
{{- $ref := (.Values.postDeployment.sqlMigration.image).tag | default .Chart.AppVersion -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s:%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s:%s" $registry $repository $ref -}}
{{- end -}}
{{- end -}}

{{/*
Building SQL migration container command based on environment and overrides
*/}}
{{- define "workbench.sqlMigrationCommand" -}}
{{- $command := (((.Values.postDeployment).sqlMigration).command) | default (list "/app/migrate_db") -}}
{{- toYaml $command -}}
{{- end -}}

{{/*
Setting resources for sql migration job based on values
*/}}
{{- define "workbench.sqlMigrationResources" -}}
{{- if (((.Values.postDeployment).sqlMigration).resources) -}}
resources:
{{- toYaml .Values.postDeployment.sqlMigration.resources | nindent 2 }}
{{- else -}}
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
{{- end -}}
{{- end -}}

{{/*
Building splunk image reference based on overrides
*/}}
{{- define "workbench.splunkImage" }}
{{- $registry := (.Values.splunk.image).registry | default (include "workbench.genericImageRegistry" .) -}}
{{- $repository := (.Values.splunk.image).repository | default "splunk/universalforwarder" -}}
{{- $ref := (.Values.splunk.image).tag | default "9.3.1" -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s:%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s:%s" $registry $repository $ref -}}
{{- end -}}
{{- end -}}

{{/*
Building datadog image reference based on environment and overrides
*/}}
{{- define "workbench.datadogImage" }}
{{- $registry := ((.Values.datadog).image).registry | default (include "workbench.imageRegistry" .) -}}
{{- $repository := ((.Values.datadog).image).repository | default "dd-apm-ubuntu" -}}
{{- $ref := ((.Values.datadog).image).tag | default "2023.11.15-DD-APM-UBUNTU-BUILD-35" -}}
{{- if and $registry $repository -}}
  {{- printf "%s/%s:%s" $registry $repository $ref -}}
{{- else -}}
  {{- printf "%s%s:%s" $registry $repository $ref -}}
{{- end -}}
{{- end -}}

{{/*
Function to check if service uses any plaintext configs - will be used to decide wether configmap will be created and if it will be used as env
*/}}
{{- define "workbench.containsAnyConfigs" -}}
{{- $defaultConfigs := default "" .Values.configuration.default -}}
{{- $envConfigs := default "" .Values.configuration.envSpecific -}}
{{ gt (add (len $defaultConfigs) (len $envConfigs)) 0 }}
{{- end -}}

{{/*
Function to check if service uses any secrets - will be used to decide wether secret will be created and if it will be used as env
*/}}
{{- define "workbench.containsAnySecrets" -}}
{{ or (gt (len .Values.vaultSecrets) 0) (.Values.splunk).enabled }}
{{- end -}}

{{/*
References to secret and configMap - we might not need this
*/}}
{{- define "workbench.envFrom" -}}
{{- $configs := (include "workbench.containsAnyConfigs" .) -}}
{{- $secrets := (include "workbench.containsAnySecrets" .) -}}
{{- if or (eq $configs "true") (eq $secrets "true") -}}
envFrom:
{{- if eq $configs "true" }}
  - configMapRef:
      name: {{ include "workbench.serviceName" . }}
{{- end -}}
{{- if eq $secrets "true" }}
  - secretRef:
      name: {{ include "workbench.serviceName" . }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Environment variables for datadog
*/}}
{{- define "workbench.datadogEnv" -}}
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: status.hostIP
- name: DD_ENV
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.labels['tags.datadoghq.com/env']
- name: DD_SERVICE
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.labels['tags.datadoghq.com/service']
- name: DD_VERSION
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.labels['tags.datadoghq.com/version']
- name: DD_LOGS_INJECTION
  value: "true"
# TODO when do we enable this?
- name: DD_PROFILING_ENABLED
  value: "false"
{{- if (eq .Values.general.language "java") }}
- name: _JAVA_OPTIONS
  value: "-javaagent:/opt/javaagent/dd-java-agent.jar"
- name: JAVA_TOOL_OPTIONS
  value: "-javaagent:/opt/javaagent/dd-java-agent.jar"
{{- end }}
{{- end -}}

{{/*
Volumes for service - can be extended per-service using values
*/}}
{{- define "workbench.volumes" -}}
- name: tmp
  emptyDir: {}
- name: logs
  emptyDir: {}
{{- if (eq .Values.general.language "java") }}
- name: shared-data
  emptyDir: {}
{{- end }}
{{- if .Values.splunk.enabled }}
- name: splunk-configs
  secret:
    secretName: {{ include "workbench.serviceName" . }} #__#SERVICE_NAME#__#
    defaultMode: 511
{{- end }}
{{- with .Values.additionalVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Volume mount for service container - can be extended per-service using values
*/}}
{{- define "workbench.serviceContainerVolumeMounts" -}}
- name: tmp
  mountPath: /tmp
- name: logs
  mountPath: /logs
{{- if (eq .Values.general.language "java") }}
- name: shared-data
  mountPath: /opt/javaagent
{{- end }}
{{- with .Values.additionalVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Datadog APM sidecar container
*/}}
{{- define "workbench.initContainers" -}}
{{- if (eq .Values.general.language "java") }}
{{- $image := include "workbench.datadogImage" . -}}
initContainers:
  - command:
      - bash
      - -c
      - |
          cp -rvf /opt/dd-apm-init-tmp/dd-java-agent.jar /opt/javaagent/dd-java-agent.jar
          if [ $? -eq 0 ]; then
            echo "dd-agent.jar saved to /opt/javaagent/"
          else
            echo "ERROR- Failed to attach dd-agent.jar " >&2
          fi
          ls -al /opt/javaagent
    name: dd-apm-init
    image: {{ $image }}
    imagePullPolicy: IfNotPresent
    resources: {}
    terminationMessagePath: /{{ include "workbench.stage" . }}/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - name: shared-data
      mountPath: /opt/javaagent
{{- end }}
{{- end -}}

{{/*
Node selector/tolerations
*/}}
{{- define "workbench.nodeConfiguration" -}}
{{- if .Values.nodeConfiguration }}
{{- with .Values.nodeConfiguration }}
{{- toYaml . }}
{{- end }}
{{- else -}}
nodeSelector:
  agentpool: services
tolerations:
  - key: "dp-services"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
{{- end }}
{{- end -}}

{{/*
Resolving image registry based on the environment
*/}}
{{- define "workbench.imageRegistry" -}}
{{- $stage := include "workbench.stage" . -}}
{{- if eq $stage "dev" -}}
g00021-pwc-gx-pwclabs-data-platform-dev-docker-local.artifacts-west.pwc.com
{{- else if eq $stage "qa" -}}
g00021-pwc-gx-pwclabs-data-platform-qa-docker-local.artifacts-west.pwc.com
{{- else if eq $stage "stage" -}}
g00021-pwc-gx-pwclabs-data-platform-stage-docker-local.artifacts-west.pwc.com
{{- else if eq $stage "prod" -}}
g00021-pwc-gx-pwclabs-data-platform-prod-docker-local.artifacts-west.pwc.com
{{- end -}}
{{- end -}}

{{/*
Resolving generic image registry
*/}}
{{- define "workbench.genericImageRegistry" -}}
g00021-pwc-gx-pwclabs-data-platform-docker.artifacts-west.pwc.com
{{- end -}}

{{/*
Image repository should match the service (chart) name
*/}}
{{- define "workbench.imageRepository" -}}
{{ .Chart.Name }}
{{- end -}}


{{/*
Image pull secret name - supplements a static, unchangeable "value" in library
*/}}
{{- define "workbench.imagePullSecrets" -}}
imagePullSecrets:
  - name: "wb-docker-jfrog"
  - name: "wb-generic-docker-jfrog"
{{- end -}}

{{/*
External secrets store - overridable by values
*/}}
{{- define "workbench.vaultExternalSecretStore" -}}
{{ (.Values.vault).externalSecretStoreName | default "pwc-vault-backend" }}
{{- end -}}

{{/*
Template to handle vault paths prefixes
*/}}
{{- define "workbench.vaultEnvPrefix" -}}
{{- $environment := (include "workbench.environment" .) -}}
{{- $envPrefix := "" -}}
{{- if eq $environment "us-dev" -}}
{{- $envPrefix = "us/lower/dev" -}}
{{- else if eq $environment "us-qa" -}}
{{- $envPrefix = "us/lower/qa" -}}
{{- else if eq $environment "us-stage" -}}
{{- $envPrefix = "us/nonprod/stage" -}}
{{- else if eq $environment "eu-stage" -}}
{{- $envPrefix = "eu/nonprod/stage" -}}
{{- else if eq $environment "us-prod" -}}
{{- $envPrefix = "us/prod/prod" -}}
{{- else if eq $environment "eu-prod" -}}
{{- $envPrefix = "eu/prod/prod" -}}
{{- else if eq $environment "sg-prod" -}}
{{- $envPrefix = "sg/prod/prod" -}}
{{- else if eq $environment "au-prod" -}}
{{- $envPrefix = "au/prod/prod" -}}
{{- end -}}
{{- $envPrefix -}}
{{- end -}}

{{/*
Template to handle vault paths for service - overridable by values
*/}}
{{- define "workbench.vaultServicePath" -}}
{{- $serviceName := (include "workbench.serviceName" .) -}}
{{- $envPrefix := (include "workbench.vaultEnvPrefix" .) -}}
{{- $default := printf "%s/data-lab/app/%s/release" $envPrefix $serviceName -}}
{{ (.Values.vault).servicePath | default $default }}
{{- end -}}

{{/*
Template to handle vault paths for splunk - overridable by values
*/}}
{{- define "workbench.vaultSplunkPath" -}}
{{- $envPrefix := (include "workbench.vaultEnvPrefix" .) -}}
{{- $default := printf "%s/data-lab/app/global/seed" $envPrefix -}}
{{ (.Values.vault).splunkPath | default $default }}
{{- end -}}

{{/*
Template to handle vault paths for splunk
*/}}
{{- define "workbench.vaultGifPathPrefix" -}}
{{- $envPrefix := (include "workbench.vaultEnvPrefix" .) -}}
{{- printf "%s/data-lab/gif-automation/" $envPrefix -}}
{{- end -}}

{{/*
Definition of splunk sidecar container
*/}}
{{- define "workbench.splunkSidecar" -}}
{{- if .Values.splunk.enabled -}}
{{- $image := include "workbench.splunkImage" . -}}
- name: splunk-uf
  image: {{ $image }}
  env:
    - name: SPLUNK_START_ARGS
      value: '--accept-license'
    - name: SPLUNK_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "workbench.serviceName" . }}
          key: splunk_password
  resources: {}
  volumeMounts:
    - name: logs
      mountPath: /monitoring
    - name: splunk-configs
      mountPath: /splunk-configs
  lifecycle:
    postStart:
      exec:
        command:
          - /bin/sh
          - '-c'
          - >
            # Copying files

            echo "waiting for the container to start for 60 sec"

            sleep 60

            echo "listing contents of /splunk-configs/"

            sudo ls /splunk-configs/

            echo "copying contents of /splunk-configs/ to
            /opt/splunkforwarder/etc/system/local/"

            sudo cp -rL /splunk-configs/*.conf
            /opt/splunkforwarder/etc/system/local/

            # Restarting splunk

            sudo /opt/splunkforwarder/bin/splunk restart
{{- end -}}
{{- end -}}

{{/*
Annotations for service versions
*/}}
{{ define "workbench.versionAnnotations" -}}
workbench.pwc.com/service-version: {{ .Chart.AppVersion | quote }}
workbench.pwc.com/service-commit-hash: {{ .Values.buildInfo.commitHash | quote }}
{{- end }}

{{/*
Annotations for service versions
*/}}
{{ define "workbench.timestampAnnotations" -}}
workbench.pwc.com/deployment-timestamp: {{ .Values.general.deploymentTimestamp | quote }}
{{- end }}

{{/*
Annotations for service versions
*/}}
{{ define "workbench.configHashAnnotations" -}}
checksum/config: {{ include ("workbench.configMap") . | sha256sum }}
checksum/external-secret: {{ include ("workbench.externalSecret") . | sha256sum }}
{{- end }}

{{/*
Annotations for library chart version
*/}}
{{ define "workbench.libraryVersionAnnotations" -}}
workbench.pwc.com/helm-library-version: {{ include "workbench.libraryChartVersion" . | quote }}
{{- end }}

{{/*
Template for service container probes as defined in the values in service helm chart
*/}}
{{ define "workbench.containerProbes" -}}
{{- if .Values.containerProbes }}
{{- with .Values.containerProbes }}
{{- toYaml . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Template for name of the created/used service account
*/}}
{{ define "workbench.serviceAccountName" -}}
{{- if and .Values.serviceAccount (hasKey .Values.serviceAccount "name") -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- $serviceName := include "workbench.serviceName" . -}}
{{- $stage := include "workbench.stage" . -}}
{{- printf "%s-%s" $serviceName $stage -}}
{{- end -}}
{{- end -}}

{{/*
Template for GIF update secret name. Input the GIF instance name.
*/}}
{{ define "workbench.gifUpdateSecretName" -}}
{{ printf "gif-update-credentials-%s" . }}
{{- end -}}


{{ define "workbench.containerPort" -}}
{{ .Values.containerPort | default 8080 }}
{{- end -}}

{{ define "workbench.servicePort" -}}
{{ .Values.servicePort | default 8080 }}
{{- end -}}

{{ define "workbench.ingressAnnotations" -}}
{{- if and .Values.ingress (hasKey .Values.ingress "annotations") -}}
{{- range $key, $value := .Values.ingress.annotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- else -}}
nginx.ingress.kubernetes.io/proxy-connect-timeout: '60'
nginx.ingress.kubernetes.io/proxy-send-timeout: '600'
nginx.ingress.kubernetes.io/proxy-read-timeout: '600'
nginx.ingress.kubernetes.io/rewrite-target: /$2
nginx.ingress.kubernetes.io/use-regex: "true"
{{- end -}}
{{- if not (and .Values.ingress (hasKey .Values.ingress "disableCertManagerAnnotations") .Values.ingress.disableCertManagerAnnotations) }}
{{- $ingressUrls := include "workbench.ingressUrls" . | split "," }}
cert-manager.io/issuer: pwc-snow-cluster-issuer
cert-manager.io/issuer-kind: PwcSnowClusterIssuer
cert-manager.io/issuer-group: cert-issuer.pwc.com
cert-manager.io/common-name: {{ $ingressUrls._0 }}
cert-manager.io/subject-organizations: PwC US LLP
cert-manager.io/subject-countries: US
cert-manager.io/subject-localities: Tampa
cert-manager.io/subject-provinces: Florida
cert-manager.io/subject-organizationalunits: PwCLabs
cert-manager.io/usages: server auth, client auth
# the snow API provisions certificates with 2year duration with no way of changing the duration. We keep this annotation for informational purposes, and to give cert-manager hint for renewal validation
cert-manager.io/duration: 17280h # 24 * 30 * 12 * 2 = 17280h = 2 years
cert-manager.io/renew-before: 1440h # 24 * 30 * 2 = 1440h = 2 months
{{- end -}}
{{- end -}}

{{ define "workbench.ingressPath" -}}
{{- if and .Values.ingress (hasKey .Values.ingress "path") -}}
{{- .Values.ingress.path -}}
{{- else -}}
/api/v1(/|$)(.*)
{{- end -}}
{{- end -}}

{{ define "workbench.ingressPathType" -}}
{{- if and .Values.ingress (hasKey .Values.ingress "pathType") -}}
{{- .Values.ingress.pathType -}}
{{- else -}}
ImplementationSpecific
{{- end -}}
{{- end -}}

{{ define "workbench.ingressSecretName" -}}
{{ $serviceName := include "workbench.serviceName" . }}
{{- if and .Values.ingress (hasKey .Values.ingress "secretName") -}}
{{- .Values.ingress.secretName -}}
{{- else -}}
{{ $serviceName }}-ngc-ingress-tls-secret
{{- end -}}
{{- end -}}

{{ define "workbench.ingressSecretNameMfe" -}}
{{ $serviceName := include "workbench.serviceName" . }}
{{- if and .Values.ingress (hasKey .Values.ingress "secretName") -}}
{{- .Values.ingress.secretName -}}
{{- else -}}
{{ $serviceName }}-ingress-tls-secret
{{- end -}}
{{- end -}}

{{ define "workbench.ingressClassName" -}}
{{- if and .Values.ingress (hasKey .Values.ingress "className") -}}
{{- .Values.ingress.className -}}
{{- else -}}
{{ $.Release.Namespace }}
{{- end -}}
{{- end -}}


{{/*
Template to calculate public URL for an arbitrary PwC service. The template cannot access global context, needs dict passed as input
*/}}
{{- define "workbench.resolvePublicUrl" -}}
{{- $stage := .stage -}}
{{- $region := .region -}}
{{- $serviceName := .serviceName -}}
{{- $envSuffix := "" -}}
{{- $domainPrefix := "" -}}

{{- if eq $stage "prod" -}}
{{- $envSuffix = $region -}}
{{- else if eq $stage "stage" -}}
{{- $envSuffix = printf "%s-stg" $region -}}
{{- $domainPrefix = "np-" -}}
{{- else -}}
{{- $envSuffix = printf "%s-%s" $region $stage -}}
{{- $domainPrefix = "lower-" -}}
{{- end -}}
{{- (printf "%s-%s.%spwclabs.pwcglb.com" $serviceName $envSuffix $domainPrefix) -}}
{{- end -}}

{{- define "workbench.ingressUrls" -}}
{{- $urls := list -}}
{{- if and .Values.ingress (hasKey .Values.ingress "urls") -}}
{{- $urls = .Values.ingress.urls -}}
{{- else -}}
{{- $serviceName := include "workbench.serviceName" . -}}
{{- $stage := include "workbench.stage" . -}}
{{- $region := include "workbench.region" . -}}
{{- $mainUrl := include "workbench.resolvePublicUrl" (dict "stage" $stage "region" $region "serviceName" $serviceName) -}}
{{- $ngcUrl := include "workbench.resolvePublicUrl" (dict "stage" $stage "region" $region "serviceName" (printf "%s-ngc" $serviceName)) -}}
{{- $urls = list $mainUrl $ngcUrl -}}
{{- end -}}
{{- join "," $urls -}}
{{- end -}}


{{/*
Common set of Prometheus-related annotations on the deployment
*/}}
{{- define "workbench.prometheusAnnotations" -}}
{{- if (.Values.annotations).prometheus -}}
{{ toYaml .Values.annotations.prometheus }}
{{- else -}}
prometheus.io/scrape: "true"
prometheus.io/path: "/actuator/prometheus"
prometheus.io/port: {{ include "workbench.containerPort" . | quote }}
{{- end }}
{{- end }}

{{/*
Deployment strategy for created deployments.
When not specified in values, will determine the percentage used by strategy based on `replicas`
*/}}
{{- define "workbench.deploymentStrategy" -}}
{{- if .Values.deploymentStrategy -}}
{{ toYaml .Values.deploymentStrategy }}
{{- else -}}
{{- $defaultPercentage := "25%" -}}
{{- if (ge (.Values.replicas | int) 5) -}}
{{- $defaultPercentage = "50%" -}}
{{- end -}}
type: RollingUpdate
rollingUpdate:
  maxSurge: {{ $defaultPercentage }}
  maxUnavailable: {{ $defaultPercentage }}
{{- end }}
{{- end }}

{{/*
Annotations required for Dapr sidecar injection.
*/}}
{{- define "workbench.daprAnnotations" -}}
{{- if (.Values.dapr).enabled -}}
{{- $daprAppId := .Values.dapr.appId -}}
{{- $containerPort := include "workbench.containerPort" . -}}
dapr.io/enabled: "true"
dapr.io/app-id: {{ $daprAppId | quote }}
dapr.io/app-port: {{ $containerPort | quote }}
dapr.io/enable-api-logging: "true"
dapr.io/log-as-json: "true"
dapr.io/app-token-secret: "app-api-token"
dapr.io/http-read-buffer-size: "32"
{{- end }}
{{- end }}

{{/*
Environment variables for dotnet hosting port configuration.
*/}}
{{- define "workbench.dotnetPortEnv" -}}
{{- if (eq .Values.general.language "dotnet") }}
{{- $containerPort := include "workbench.containerPort" . -}}
- name: ASPNETCORE_URLS
  value: {{ printf "http://*:%s/" $containerPort | quote }}
{{- end }}
{{- end -}}
