
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
| `rhdhOperator.secretRef.k8s.clusterToken` | Key in the secret with name defined in the 'name' field that contains the value of the Kubernetes API bearer token used for authentication. Defaults to 'K8S_CLUSTER_TOKEN', empty for not available. | `"K8S_CLUSTER_TOKEN"` |
| `rhdhOperator.secretRef.k8s.clusterUrl` | Key in the secret with name defined in the 'name' field that contains the value of the API URL of the kubernetes cluster. Defaults to 'K8S_CLUSTER_URL', empty for not available. | `"K8S_CLUSTER_URL"` |
| `rhdhOperator.secretRef.argocd.url` | Key in the secret with name defined in the 'name' field that contains the value of the URL of the ArgoCD API server. Defaults to 'ARGOCD_URL', empty for not available. | `"ARGOCD_URL"` |
| `rhdhOperator.secretRef.argocd.username` | Key in the secret with name defined in the 'name' field that contains the value of the username to login to ArgoCD. Defaults to 'ARGOCD_USERNAME', empty for not available. | `"ARGOCD_USERNAME"` |
| `rhdhOperator.secretRef.argocd.password` | Key in the secret with name  defined in the 'name' field that contains the value of the password to authenticate to ArgoCD. Defaults to 'ARGOCD_PASSWORD', empty for not available. | `"ARGOCD_PASSWORD"` |
| `rhdhOperator.subscription.namespace` | namespace where the operator should be deployed | `"rhdh-operator"` |
| `rhdhOperator.subscription.channel` | channel of an operator package to subscribe to | `"fast"` |
| `rhdhOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `rhdhOperator.subscription.name` | name of the operator package | `"rhdh"` |
| `rhdhPlugins.npmRegistry` |  | `""` |
| `rhdhPlugins.scope` |  | `"@janus-idp"` |
| `rhdhPlugins.orchestrator.package` |  | `"backstage-plugin-orchestrator@1.10.6"` |
| `rhdhPlugins.orchestrator.integrity` |  | `"sha512-qSXQ2O7/eLBEF186PzaRfzLfutFYUq9MdiiIZbHejz+KML9rVInPJkc1tine3R3JQVuw1QBIQ2vhPNbGbHXWZg=="` |
| `rhdhPlugins.orchestrator_backend.package` |  | `"backstage-plugin-orchestrator-backend-dynamic@1.8.0"` |
| `rhdhPlugins.orchestrator_backend.integrity` |  | `"sha512-wVZE7Dak10edxh1ZEckzYKrE13GrqhzSVelURhxjZcgXEHdGPWYUFHNMEpte7hzIBE85350Ka7fpy7C4BNPvEw=="` |
| `rhdhPlugins.notifications.package` |  | `"plugin-notifications@1.2.5"` |
| `rhdhPlugins.notifications.integrity` |  | `"sha512-BQ7ujmrbv2MLelNGyleC4Z8fVVywYBMYZTwmRC534WCT38QHQ0cWJbebOgeIYszFA98STW4F5tdKbVot/2gWMg=="` |
| `rhdhPlugins.notifications_backend.package` |  | `"plugin-notifications-backend-dynamic@1.4.11"` |
| `rhdhPlugins.notifications_backend.integrity` |  | `"sha512-5zluThJwFVKX0Wlh4E15vDKUFGu/qJ0UsxHYWoISJ+ing1R38gskvN3kukylNTgOp8B78OmUglPfNlydcYEHvA=="` |
| `postgres.serviceName` | The name of the Postgres DB service to be used by platform services. Cannot be empty. | `"sonataflow-psql-postgresql"` |
| `postgres.serviceNamespace` | The namespace of the Postgres DB service to be used by platform services. | `"sonataflow-infra"` |
| `postgres.authSecret.name` | name of existing secret to use for PostgreSQL credentials. | `"sonataflow-psql-postgresql"` |
| `postgres.authSecret.userKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-username"` |
| `postgres.authSecret.passwordKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-password"` |
| `postgres.database` | existing database instance used by data index and job service | `"sonataflow"` |
| `orchestrator.namespace` | Namespace where sonataflow's workflows run. The value is captured when running the setup.sh script and stored as a label in the selected namespace. User can override the value by populating this field. Defaults to `sonataflow-infra`. | `"sonataflow-infra"` |
| `orchestrator.sonataPlatform.resources.requests.memory` |  | `"64Mi"` |
| `orchestrator.sonataPlatform.resources.requests.cpu` |  | `"250m"` |
| `orchestrator.sonataPlatform.resources.limits.memory` |  | `"1Gi"` |
| `orchestrator.sonataPlatform.resources.limits.cpu` |  | `"500m"` |
| `tekton.enabled` | whether to create the Tekton pipeline resources | `false` |
| `argocd.enabled` | whether to install the ArgoCD plugin and create the orchestrator AppProject | `false` |
| `argocd.namespace` | Defines the namespace where the orchestrator's instance of ArgoCD is deployed. The value is captured when running setup.sh script and stored as a label in the selected namespace. User can override the value by populating this field. Defaults to `orchestrator-gitops` in the setup.sh script. | `""` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

