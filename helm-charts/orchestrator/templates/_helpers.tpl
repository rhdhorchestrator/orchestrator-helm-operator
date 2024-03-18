{{/* Helper functions */}}

{{- define "unmanaged-resource-exists" -}}
    {{- $api := index . 0 -}}
    {{- $kind := index . 1 -}}
    {{- $namespace := index . 2 -}}
    {{- $name := index . 3 -}}
    {{- $releaseName := index . 4 -}}
    {{- $apiCapabilities := index . 5 -}}
    {{- $unmanagedSubscriptionExists := "true" -}}
    {{- if $apiCapabilities.Has (printf "%s/%s" $api $kind) }}
        {{- $existingOperator := lookup $api $kind $namespace $name -}}
        {{- if empty $existingOperator -}}
            {{- "false" -}}
        {{- else -}}
            {{- $isManagedResource := include "is-managed-resource" (list $existingOperator $releaseName) -}}
            {{- if eq $isManagedResource "true" -}}
                {{- "false" -}}
            {{- else -}}
                {{- "true" -}}
            {{- end -}}
        {{- end -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "is-managed-resource" -}}
    {{- $resource := index . 0 -}}
    {{- $releaseName := index . 1 -}}
    {{- $resourceReleaseName := dig "metadata" "annotations" (dict "meta.helm.sh/release-name" "NA") $resource -}}
    {{- if eq (get $resourceReleaseName "meta.helm.sh/release-name") $releaseName -}}
        {{- "true" -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "is-openshift" -}}
    {{- if .Capabilities.APIVersions.Has "route.openshift.io/v1" -}}
        {{- "true" -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "get-default-catalogsource-name" -}}
    {{- if .Capabilities.APIVersions.Has "route.openshift.io/v1" -}}
        {{- "community-operators" -}}
    {{- else -}}
        {{- "operatorhubio-catalog" -}}
    {{- end -}}
{{- end -}}

{{- define "get-default-catalogsource-namespace" -}}
    {{- if .Capabilities.APIVersions.Has "route.openshift.io/v1" -}}
        {{- "openshift-marketplace" -}}
    {{- else -}}
        {{- "olm" -}}
    {{- end -}}
{{- end -}}

{{- define "get-default-operator-namespace" -}}
    {{- if .Capabilities.APIVersions.Has "route.openshift.io/v1" -}}
        {{- "openshift-operators" -}}
    {{- else -}}
        {{- "operators" -}}
    {{- end -}}
{{- end -}}

{{- define "operator-group-exists" -}}
    {{- $namespace := index . 0 -}}
    {{- $existingOperatorGroup := lookup "operators.coreos.com/v1" "OperatorGroup" $namespace "" -}}
    {{- if empty $existingOperatorGroup -}}
        {{- "false" -}}
    {{- else }}
        {{- "true" -}}
    {{- end -}}
{{- end -}}

{{- define "cluster.domain" -}}
    {{- if .Capabilities.APIVersions.Has "config.openshift.io/v1/Ingress" -}}  
        {{- $cluster := (lookup "config.openshift.io/v1" "Ingress" "" "cluster") -}}
        {{- if and (hasKey $cluster "spec") (hasKey $cluster.spec "domain") -}}
            {{- printf "%s" $cluster.spec.domain -}}
        {{- else -}}
            {{ "cluster.domain" }}
        {{- end }}
    {{- else -}}
        {{ fail "Unable to obtain cluster domain, config.openshift.io/v1/Ingress is missing" }}
    {{- end -}}
{{- end -}}


{{- define "install-tekton-task" -}}
  {{- if and (or .Values.orchestrator.devmode .Values.tekton.enabled) (ne .Values.rhdhOperator.k8s.clusterToken "") (.Capabilities.APIVersions.Has "tekton.dev/v1beta1/Task") }}
        {{- "true" -}}
    {{- else }}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "install-tekton-pipeline" -}}
  {{- if and (or .Values.orchestrator.devmode .Values.tekton.enabled) (ne .Values.rhdhOperator.k8s.clusterToken "") (.Capabilities.APIVersions.Has "tekton.dev/v1/Pipeline") }}
        {{- "true" -}}
    {{- else }}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "install-argocd-project" -}}
    {{- if and (or .Values.orchestrator.devmode .Values.argocd.enabled) (.Capabilities.APIVersions.Has "argoproj.io/v1alpha1/AppProject") }}
        {{- "true" -}}
    {{- else }}
        {{- "false" -}}
    {{- end -}}
{{- end -}}
