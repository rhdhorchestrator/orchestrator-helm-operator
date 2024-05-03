{{- define "manage-cr-lifecycle-on-action" }}
  {{- $resourceAPIGroup := printf "%s.%s" .kinds .apiGroup }}
  {{- $releaseNameKind := printf "%s-%s" .release.Name .kind |lower }}
  {{- if .isEnabled }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $releaseNameKind }}
  namespace: {{ .release.Namespace }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ $releaseNameKind }}
rules:
  - apiGroups:
    - apiextensions.k8s.io
    resources:
    - customresourcedefinitions
    verbs:
    - get
  - apiGroups:
    - {{ .apiGroup }}
    resources:
    - {{ .kinds |lower}}
    verbs:
    - patch
    - update
    - create
    - get
    - list
    - delete
    - watch
  - apiGroups:
    - batch
    resources:
    - cronjobs
    verbs:
    - delete
    - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ $releaseNameKind }}
subjects:
  - kind: ServiceAccount
    name: {{ $releaseNameKind }}
    namespace: {{ .release.Namespace }}
roleRef:
  kind: ClusterRole
  name: {{ $releaseNameKind }}
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ trunc -52 (printf "%s-reconcile" $releaseNameKind | trimPrefix "-" | trimPrefix "_" ) }} # Fixes https://github.com/parodos-dev/orchestrator-helm-chart/issues/160
  # job name is used in the spec.template.metadata.labels, and labels cannot be more than 63 characters https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  namespace: {{ .release.Namespace }}
  labels:
    "orchestrator.rhdh.redhat.com/reconciles": {{ $resourceAPIGroup }}
spec:
  schedule: '* * * * *' #run every minute
  concurrencyPolicy: Replace
  successfulJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          serviceAccountName: {{ $releaseNameKind }}
          containers:
            - name: job
              image: registry.redhat.io/openshift4/ose-cli:latest
              env:
                - name: MANIFEST
                  value: {{ .manifest }}
              command:
                - "bin/bash"
                - "-c"
              args:
                - |
                  echo "Update Job for CR {{ .kind }} of {{ $resourceAPIGroup }} started"
                  echo "Checking for availability of CRD {{ printf "%s.%s" .kinds .apiGroup }}"
                  count=60
                  while [[ count -ne 0 ]]
                  do
                    kubectl get crd {{ printf "%s.%s" .kinds .apiGroup }} -oname
                    if [[ $? -eq 0 ]]; then
                      echo $MANIFEST | base64 -d | kubectl apply -f -
                      if [[ $? -eq 0 ]]; then
                        echo "Update Job finished"
                        exit 0
                      fi
                      exit 1
                    fi
                    ((count--))
                    sleep 5
                  done
                  echo "Could not find CRD {{ printf "%s.%s" .kinds .apiGroup }} deployed"
                  exit 1
  {{- end }}
  {{ if or (.isEnabled) (and (not .isEnabled) (and .hasCRDInstalled (not (empty (lookup (printf "%s/%s" .apiGroup .groupVersion) .kind (dig "targetNamespace" "" . ) .resourceName ))))) }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ trunc -57 (printf "%s-delete" $releaseNameKind) | trimPrefix "-" | trimPrefix "_" }} # Fixes https://github.com/parodos-dev/orchestrator-helm-chart/issues/160
  # job name is used in the spec.template.metadata.labels, and labels cannot be more than 63 characters https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  namespace: {{ .release.Namespace }}
  annotations:
    "helm.sh/hook": {{ if .isEnabled }}pre-delete{{ end }}{{ if and (not .isEnabled) (not (empty (lookup (printf "%s/%s" .apiGroup .groupVersion) .kind (dig "targetNamespace" "" . ) .resourceName ))) }}pre-upgrade,pre-rollback{{ end }}
    "helm.sh/hook-delete-policy": before-hook-creation
    "helm.sh/hook-weight": "1"
spec:
  template:
    metadata:
      name: {{ $releaseNameKind }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ $releaseNameKind }}
      containers:
        - name: cleanup
          image: registry.redhat.io/openshift4/ose-cli:latest
          command:
            - "bin/bash"
            - "-c"
          args:
            - |
              echo "Cleanup Job for CR {{ .kind }} of {{ $resourceAPIGroup }} started"
              kubectl get crd {{ $resourceAPIGroup }}
              if [ $? -eq 0 ]; then
                kubectl delete cronjob -l orchestrator.rhdh.redhat.com/reconciles={{ $resourceAPIGroup }} -n {{ .release.Namespace }} # Ensure no race condition happens where a cronjob's spawned job creates the CR after the delete job is completed and while helm is processing the other delete jobs
                kubectl get {{ if (hasKey . "targetNamespace") }} -n {{ .targetNamespace }} {{ end }} {{ $resourceAPIGroup }} {{ .resourceName }}
                if [ $? -eq 0 ]; then
                  kubectl delete {{ if (hasKey . "targetNamespace") }} -n {{ .targetNamespace }} {{ end }} {{ $resourceAPIGroup }} {{ .resourceName }}
                  exit 0
                fi
              fi
              echo "Cleanup Job finished"
  {{- end }}
{{- end }}