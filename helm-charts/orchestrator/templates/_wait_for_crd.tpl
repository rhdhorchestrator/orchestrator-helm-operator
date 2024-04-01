{{- define "wait-for-crd-available" -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
  namespace: {{ .releaseNamespace }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
rules:
  - apiGroups:
    - apiextensions.k8s.io
    resources:
    - customresourcedefinitions
    verbs:
    - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
subjects:
  - kind: ServiceAccount
    name: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
    namespace: {{ .releaseNamespace }}
roleRef:
  kind: ClusterRole
  name: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
  namespace: {{ .releaseNamespace }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "1"
spec:
  template:
    metadata:
      name: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
    spec:
      serviceAccountName: {{ printf "%s-%s-crd-availability-check" .releaseName .kind }}
      restartPolicy: Never
      containers:
      - name: deploy-manifest
        image: registry.redhat.io/openshift4/ose-cli:latest
        command:
          - "bin/bash"
          - "-c"
        args:
          - |
            echo "Wait for availability of CRD {{ printf "%s.%s" .kind .apiGroup }}"
            count=60
            while [[ count -ne 0 ]]
            do
              kubectl get crd {{ printf "%s.%s" .kind .apiGroup }} -oname
              if [[ $? -eq 0 ]]; then
                echo "Job finished"
                exit 0
              fi
              ((count--))
              sleep 5
            done
            echo "Could not find CRD {{ printf "%s.%s" .kind .apiGroup }} deployed"
{{- end -}}