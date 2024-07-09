
Orchestrator
===========

Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving.



## Configuration

The following table lists the configurable parameters of the Orchestrator chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `sonataFlowOperator.isReleaseCandidate` | Indicates RC builds should be used by the chart to install Sonataflow | `false` |
| `sonataFlowOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `sonataFlowOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless-logic"` |
| `sonataFlowOperator.subscription.channel` | channel of an operator package to subscribe to | `"alpha"` |
| `sonataFlowOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `sonataFlowOperator.subscription.name` | name of the operator package | `"logic-operator-rhel8"` |
| `sonataFlowOperator.subscription.sourceName` | name of the catalog source | `"redhat-operators"` |
| `sonataFlowOperator.subscription.startingCSV` | The initial version of the operator | `""` |
| `serverlessOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `serverlessOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless"` |
| `serverlessOperator.subscription.channel` | channel of an operator package to subscribe to | `"stable"` |
| `serverlessOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `serverlessOperator.subscription.name` | name of the operator package | `"serverless-operator"` |
| `serverlessOperator.subscription.sourceName` | name of the catalog source | `"redhat-operators"` |
| `rhdhOperator.isReleaseCandidate` | Indicates RC builds should be used by the chart to install RHDH | `false` |
| `rhdhOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `rhdhOperator.enableGuestProvider` | whether to enable guest provider | `true` |
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
| `rhdhOperator.subscription.source` | name of the catalog source | `"redhat-operators"` |
| `rhdhOperator.subscription.startingCSV` | The initial version of the operator | `""` |
| `rhdhPlugins.npmRegistry` |  | `"https://npm.stage.registry.redhat.com"` |
| `rhdhPlugins.scope` |  | `"@redhat"` |
| `rhdhPlugins.orchestrator.package` |  | `"backstage-plugin-orchestrator@1.1.0-rc.0-0"` |
| `rhdhPlugins.orchestrator.integrity` |  | `"sha512-uxkNFS/4nkVM6FRq0Uvnznvxcm/3MNdh11R6sRsbmKCP4KF4N9T2GF4lgfD7J+p7EuGMD4UFnjKjaR77v0NGaQ=="` |
| `rhdhPlugins.orchestrator_backend.package` |  | `"backstage-plugin-orchestrator-backend-dynamic@1.1.0-rc.0-0"` |
| `rhdhPlugins.orchestrator_backend.integrity` |  | `"sha512-NIIGpwH/uJaMknTdORdnqsHfPeI/OrAl2biqELal1e9tK2r6PrVWfIWr9XoH5AfOjtQjbeAe7joiLwhM+uyVAw=="` |
| `rhdhPlugins.notifications.package` |  | `"plugin-notifications-dynamic@0.2.0-rc.0-0"` |
| `rhdhPlugins.notifications.integrity` |  | `"sha512-wmISWN02G4OiBF7y8Jpl5KCbDfhzl70s+r0h2tdVh1IIwYmojH5pqXFQAhDd3FTlqYc8yqDG8gEAQ8v66qbU1g=="` |
| `rhdhPlugins.notifications_backend.package` |  | `"plugin-notifications-backend-dynamic@0.2.0-rc.0-0"` |
| `rhdhPlugins.notifications_backend.integrity` |  | `"sha512-2Eqi1SWIy1vIWcR0hjSCfRP2w9z+qFdpKsB3dmbssv4Pg98AFj41LYlrTLscHri7am6cd4xe1fEb7gJGqbNQiQ=="` |
| `rhdhPlugins.signals.package` |  | `"plugin-signals-dynamic@0.0.5-rc.0-0"` |
| `rhdhPlugins.signals.integrity` |  | `"sha512-5Iwp9gF6VPiMLJ5NUw5s5Z17AuJ5XYS97wghNTfcmah/OFxTmgZHWxvhcRoXDRQvyj4nc/gOZes74kp6kZ9XDg=="` |
| `rhdhPlugins.signals_backend.package` |  | `"plugin-signals-backend-dynamic@0.1.3-rc.0-0"` |
| `rhdhPlugins.signals_backend.integrity` |  | `"sha512-LlkM2Mf2QTndsS6eBzyXDhJmRTHLpAku3hhlvWhtQChSLTFCtNGRTIQA5WHG7NqLH0QqBz+UcEjX7Vca82QKKg=="` |
| `rhdhPlugins.notifications_email.package` |  | `"plugin-notifications-backend-module-email-dynamic@0.0.0-rc.0-0"` |
| `rhdhPlugins.notifications_email.integrity` |  | `"sha512-TikxFBxBHKJYZy8go+Mw+7yjfSJILgXjr4K0C0+tnKyMOn+OqIX6K8c1fq7IdXto3fftQ+mmCrBqJem25JjVnA=="` |
| `postgres.serviceName` | The name of the Postgres DB service to be used by platform services. Cannot be empty. | `"sonataflow-psql-postgresql"` |
| `postgres.serviceNamespace` | The namespace of the Postgres DB service to be used by platform services. | `"sonataflow-infra"` |
| `postgres.authSecret.name` | name of existing secret to use for PostgreSQL credentials. | `"sonataflow-psql-postgresql"` |
| `postgres.authSecret.userKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-username"` |
| `postgres.authSecret.passwordKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-password"` |
| `postgres.database` | existing database instance used by data index and job service | `"sonataflow"` |
| `orchestrator.namespace` | Namespace where sonataflow's workflows run. The value is captured when running the setup.sh script and stored as a label in the selected namespace. User can override the value by populating this field. Defaults to `sonataflow-infra`. | `"sonataflow-infra"` |
| `orchestrator.sonataflowPlatform.resources.requests.memory` |  | `"64Mi"` |
| `orchestrator.sonataflowPlatform.resources.requests.cpu` |  | `"250m"` |
| `orchestrator.sonataflowPlatform.resources.limits.memory` |  | `"1Gi"` |
| `orchestrator.sonataflowPlatform.resources.limits.cpu` |  | `"500m"` |
| `tekton.enabled` | whether to create the Tekton pipeline resources | `false` |
| `argocd.enabled` | whether to install the ArgoCD plugin and create the orchestrator AppProject | `false` |
| `argocd.namespace` | Defines the namespace where the orchestrator's instance of ArgoCD is deployed. The value is captured when running setup.sh script and stored as a label in the selected namespace. User can override the value by populating this field. Defaults to `orchestrator-gitops` in the setup.sh script. | `""` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

