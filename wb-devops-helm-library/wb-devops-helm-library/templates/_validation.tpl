
{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "workbench.validation" -}}
{{- $messages := list -}}

{{- $messages = append $messages (trim (include "workbench.validate.environment" .)) -}}
{{- $messages = append $messages (trim (include "workbench.validate.language" .)) -}}
{{- $messages = append $messages (trim (include "workbench.validate.valueStream" .)) -}}
{{- $messages = append $messages (trim (include "workbench.validate.ciid" .)) -}}

{{- $messages = without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALIDATIONS:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/*
Validate if environment is known
*/}}
{{- define "workbench.validate.environment" -}}
{{- $environment := (include "workbench.environment" .) -}}
{{- if eq $environment "us-dev" -}}
{{- else if eq $environment "us-qa" -}}
{{- else if eq $environment "us-stage" -}}
{{- else if eq $environment "eu-stage" -}}
{{- else if eq $environment "us-prod" -}}
{{- else if eq $environment "eu-prod" -}}
{{- else if eq $environment "sg-prod" -}}
{{- else if eq $environment "au-prod" -}}
{{- else -}}
Unknown environment {{ $environment }}
{{- end -}}
{{- end -}}

{{/*
Validate if language is supported
*/}}
{{- define "workbench.validate.language" -}}
{{- $language := .Values.general.language -}}
{{- if eq $language "java" -}}
{{- else if eq $language "dotnet" -}}
{{- else if eq $language "node" -}}
{{- else if eq $language "python" -}}
{{- else if eq $language "html" -}}
{{- else -}}
Unknown language {{ $language }}
{{- end -}}
{{- end -}}

{{/*
Validate value stream
*/}}
{{- define "workbench.validate.valueStream" -}}
{{- $valueStream := .Values.general.valueStream -}}
{{- if not $valueStream -}}
Missing value for valueStream
{{- end -}}
{{- end -}}

{{/*
Validate CIID
*/}}
{{- define "workbench.validate.ciid" -}}
{{- $ciid := .Values.general.ciid -}}
{{- if not $ciid -}}
Missing value for CIID
{{- end -}}
{{- end -}}

{{/*
We will also want to validate other values from the parent (service) chart
- supported language
- Team (not sure if we need validation explicit values, but it might be useful to make sure its at least there)
- serviceContainerCommand needs to be set?
- resources need to be set
- hpa values need to be set
*/}}
