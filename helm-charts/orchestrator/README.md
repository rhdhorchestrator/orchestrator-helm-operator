
Orchestrator
===========

Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving.



## Configuration

The following table lists the configurable parameters of the Orchestrator chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `sonataFlowOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `sonataFlowOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless-logic"` |
| `sonataFlowOperator.subscription.channel` | channel of an operator package to subscribe to | `"alpha"` |
| `sonataFlowOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `sonataFlowOperator.subscription.name` | name of the operator package | `"logic-operator-rhel8"` |
| `serverlessOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `serverlessOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless"` |
| `serverlessOperator.subscription.channel` | channel of an operator package to subscribe to | `"stable"` |
| `serverlessOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `serverlessOperator.subscription.name` | name of the operator package | `"serverless-operator"` |
| `rhdhOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `rhdhOperator.secretRef.name` | name of the secret that contains the credentials for the plugin to establish a communication channel with the Kubernetes API, ArgoCD and GitHub servers. | `"backstage-backend-auth-secret"` |
| `rhdhOperator.secretRef.backstage.backendSecret` | Key in the secret with name defined in the 'name' field that contains the value of the Backstage backend secret. Defaults to 'BACKEND_SECRET'. It's required. | `"BACKEND_SECRET"` |
| `rhdhOperator.secretRef.github.token` | Key in the secret with name defined in the 'name' field that contains the value of the authentication token as expected by GitHub. Required for importing resource to the catalog, launching software templates and more. Defaults to 'GITHUB_TOKEN', empty for not available. | `"GITHUB_TOKEN"` |
| `rhdhOperator.secretRef.github.clientId` | Key in the secret with name defined in the 'name' field that contains the value of the client ID that you generated on GitHub, for GitHub authentication (requires GitHub App). Defaults to 'GITHUB_CLIENT_ID', empty for not available. | `"GITHUB_CLIENT_ID"` |
| `rhdhOperator.secretRef.github.clientSecret` | Key in the secret with name defined in the 'name' field that contains the value of the client secret tied to the generated client ID. Defaults to 'GITHUB_CLIENT_SECRET', empty for not available. | `"GITHUB_CLIENT_SECRET"` |
| `rhdhOperator.secretRef.k8s.clusterToken` | Key in the secret with name defined in the 'name' field that contains the value of the Kubernetes API bearer token used for authentication. Defaults to 'K8S_CLUSTER_URL', empty for not available. | `"K8S_CLUSTER_URL"` |
| `rhdhOperator.secretRef.k8s.clusterUrl` | Key in the secret with name defined in the 'name' field that contains the value of the API URL of the kubernetes cluster. Defaults to 'K8S_CLUSTER_TOKEN', empty for not available. | `"K8S_CLUSTER_TOKEN"` |
| `rhdhOperator.secretRef.argocd.url` | Key in the secret with name defined in the 'name' field that contains the value of the URL of the ArgoCD API server. Defaults to 'ARGOCD_URL', empty for not available. | `"ARGOCD_URL"` |
| `rhdhOperator.secretRef.argocd.username` | Key in the secret with name defined in the 'name' field that contains the value of the username to login to ArgoCD. Defaults to 'ARGOCD_USERNAME', empty for not available. | `"ARGOCD_USERNAME"` |
| `rhdhOperator.secretRef.argocd.password` | Key in the secret with name  defined in the 'name' field that contains the value of the password to authenticate to ArgoCD. Defaults to 'ARGOCD_PASSWORD', empty for not available. | `"ARGOCD_PASSWORD"` |
| `rhdhOperator.subscription.namespace` | namespace where the operator should be deployed | `"rhdh-operator"` |
| `rhdhOperator.subscription.channel` | channel of an operator package to subscribe to | `"fast"` |
| `rhdhOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `rhdhOperator.subscription.name` | name of the operator package | `"rhdh"` |
| `rhdhPlugins.npmRegistry` |  | `""` |
| `rhdhPlugins.scope` |  | `"@janus-idp"` |
| `rhdhPlugins.orchestrator.package` |  | `"backstage-plugin-orchestrator@1.9.4"` |
| `rhdhPlugins.orchestrator.integrity` |  | `"sha512-d0kLVkdsWMxGkOOS1wB+u24mIdF0isNY4I0F3/eR/g0lI0q+uFJ8iW+8XmyaHKqa1ZMvg5pnMljJ6thJk85nSg=="` |
| `rhdhPlugins.orchestrator_backend.package` |  | `"backstage-plugin-orchestrator-backend-dynamic@1.6.8"` |
| `rhdhPlugins.orchestrator_backend.integrity` |  | `"sha512-Akb9digwa3b1tOXbfbm13Z+DIZV/lBaNX0HDXhaciYE4dWPPzB17/4eT74suim9e8k4THORGVIM/GC/f2HwMNQ=="` |
| `rhdhPlugins.notifications.package` |  | `"plugin-notifications@1.2.0"` |
| `rhdhPlugins.notifications.integrity` |  | `"sha512-T00TKMTeLQoMTY6UnXuXpPXFN2f+w32i8qECpAe3yeZM1TJb2oe6hCNwzAdKjGGPlGPAGqc16IBpZV65rfM79Q=="` |
| `rhdhPlugins.notifications_backend.package` |  | `"plugin-notifications-backend-dynamic@1.4.6"` |
| `rhdhPlugins.notifications_backend.integrity` |  | `"sha512-40hMkr/+5GdapDUuYBIwzZQLpPRJQxFIrr0PFACS40lmG98XcWP6HZ7dQ+VvZ1gAFnWU9HscIrWMwrlvtZ237g=="` |
| `postgres.serviceName` | The name of the Postgres DB service to be used by platform services. Cannot be empty. | `"sonataflow-psql-postgresql"` |
| `postgres.serviceNamespace` | The namespace of the Postgres DB service to be used by platform services. | `"sonataflow-infra"` |
| `postgres.authSecret.name` | name of existing secret to use for PostgreSQL credentials. | `"sonataflow-psql-postgresql"` |
| `postgres.authSecret.userKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-username"` |
| `postgres.authSecret.passwordKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-password"` |
| `postgres.database` | existing database instance used by data index and job service | `"sonataflow"` |
| `orchestrator.namespace` | namespace where the data index, job service and workflows are deployed | `"sonataflow-infra"` |
| `orchestrator.sonataPlatform.resources.requests.memory` |  | `"64Mi"` |
| `orchestrator.sonataPlatform.resources.requests.cpu` |  | `"250m"` |
| `orchestrator.sonataPlatform.resources.limits.memory` |  | `"1Gi"` |
| `orchestrator.sonataPlatform.resources.limits.cpu` |  | `"500m"` |
| `tekton.enabled` | whether to create the Tekton pipeline resources | `false` |
| `argocd.enabled` | whether to install the ArgoCD plugin and create the orchestrator AppProject | `false` |
| `argocd.namespace` |  | `"orchestrator-gitops"` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

