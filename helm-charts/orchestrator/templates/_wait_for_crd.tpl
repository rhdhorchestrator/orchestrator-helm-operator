{{- define "wait-for-crd-available" -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ printf "%s-crd-%s" .releaseName .resourceName }}
  namespace: {{ .releaseNamespace }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"  
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ printf "%s-crd-%s" .releaseName .resourceName }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
rules:
  - apiGroups: 
    - {{ .apiGroup }}
    resources:
    - {{ .resourceName }}
    verbs:
    - get 
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ printf "%s-crd-%s" .releaseName .resourceName }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
subjects:
  - kind: ServiceAccount
    name: {{ printf "%s-crd-%s" .releaseName .resourceName }}
    namespace: {{ .releaseNamespace }}
roleRef:
  kind: ClusterRole
  name: {{ printf "%s-crd-%s" .releaseName .resourceName }}
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "%s-crd-%s" .releaseName .resourceName }}
  namespace: {{ .releaseNamespace }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded # add ,hook-failed once verified
    "helm.sh/hook-weight": "1"    
spec:
  template:
    metadata:
      name: {{ printf "%s-crd-%s" .releaseName .resourceName }}
    spec:
      serviceAccountName: {{ printf "%s-crd-%s" .releaseName .resourceName }}
      restartPolicy: Never
      containers:
      - name: deploy-manifest
        image: registry.redhat.io/openshift4/ose-cli:latest
        command:
          - "bin/bash"
          - "-c"
        args:
          - |
            echo "Wait for condition"
            count=60
            while [[ count -ne 0 ]]
            do
              kubectl get {{ printf "%s.%s" .resourceName .apiGroup }} 1>&2 2>/dev/null
              if [[ $? -eq 0 ]]; then
                exit 0
              fi
              ((count--))
              sleep 5
            done
            echo "Job finished"
---
{{- end -}}