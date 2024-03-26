{{- define "delete-cr-on-uninstall" }}
  {{ $resourceAPIGroup := printf "%s.%s" .kind .apiGroup }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  namespace: {{ .releaseNamespace }}
  annotations:
    "helm.sh/hook": pre-delete
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "-1"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  annotations:
    "helm.sh/hook": pre-delete
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
rules:
  - apiGroups:
    - apiextensions.k8s.io
    resources:
    - customresourcedefinitions
    verbs:
    - get
{{- if not (hasKey . "targetNamespace") }}
  - apiGroups: # Tackling cluster scoped resources such as sonataflowclusterplatform
    - {{ .apiGroup }}
    resources:
    - {{ .kind }}
    verbs:
    - get
    - list
    - delete
{{- end }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  annotations:
    "helm.sh/hook": pre-delete
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
subjects:
  - kind: ServiceAccount
    name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
    namespace: {{ .releaseNamespace }}
roleRef:
  kind: ClusterRole
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  apiGroup: rbac.authorization.k8s.io 
---
{{- if (hasKey . "targetNamespace") }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  namespace: {{ .targetNamespace }}
  annotations:
    "helm.sh/hook": pre-delete
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"    
rules:
  - apiGroups:
    - {{ .apiGroup }}
    resources:
    - {{ .kind}}
    verbs:
    - get
    - list
    - delete
    - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  namespace: {{ .targetNamespace }}
  annotations:
    "helm.sh/hook": pre-delete
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"    
subjects:
  - kind: ServiceAccount
    name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
    namespace: {{ .releaseNamespace }}
roleRef:
  kind: Role
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  apiGroup: rbac.authorization.k8s.io
{{- end }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
  namespace: {{ .releaseNamespace }}
  annotations:
    "helm.sh/hook": pre-delete
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "1"
spec:
  template:
    metadata:
      name: {{ printf "%s-%s-cleanup" .releaseName .kind }}
    spec:
      serviceAccountName: {{ printf "%s-%s-cleanup" .releaseName .kind }}
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
                kubectl get {{ if (hasKey . "targetNamespace") }} -n {{ .targetNamespace }} {{ end }} {{ $resourceAPIGroup }} {{ .resourceName }}
                if [ $? -eq 0 ]; then
                  kubectl delete {{ if (hasKey . "targetNamespace") }} -n {{ .targetNamespace }} {{ end }} {{ $resourceAPIGroup }} {{ .resourceName }}
                fi
              fi
              echo "Cleanup Job finished"
      restartPolicy: Never
{{- end }}