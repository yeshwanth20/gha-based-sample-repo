{{/*
Get library chart version. We keep this string "<library-chart-version>" which gets replaced in CI.
This is because there is not easy way to reference version of library chart from the application chart
*/}}
{{ define "workbench.libraryChartVersion" -}}
<library-chart-version>
{{- end -}}
