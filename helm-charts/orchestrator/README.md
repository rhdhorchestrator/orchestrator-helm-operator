
Orchestrator
===========

Helm chart to deploy the Orchestrator solution suite on OpenShift, including Janus IDP backstage, SonataFlow Operator, OpenShift Serverless Operator, Knative Eventing and Knative Serving.



## Configuration

The following table lists the configurable parameters of the Orchestrator chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `sonataFlowOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `sonataFlowOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-operators"` |
| `sonataFlowOperator.subscription.channel` | channel of an operator package to subscribe to | `"alpha"` |
| `sonataFlowOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `sonataFlowOperator.subscription.pkgName` | name of the operator package | `"sonataflow-operator"` |
| `sonataFlowOperator.subscription.sourceImage` | catalog image of the development build. Unset it for the release build. | `"quay.io/masayag/kogito-serverless-operator-catalog:v999.0.0-snapshot"` |
| `sonataFlowOperator.subscription.sourceNamespace` | namespace of the catalog source | `"openshift-marketplace"` |
| `sonataFlowOperator.subscription.source` | name of the catalog source for the operator | `"sonataflow-operator"` |
| `serverlessOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `serverlessOperator.subscription.namespace` | namespace where the operator should be deployed | `"openshift-serverless"` |
| `serverlessOperator.subscription.channel` | channel of an operator package to subscribe to | `"stable"` |
| `serverlessOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `serverlessOperator.subscription.pkgName` | name of the operator package | `"serverless-operator"` |
| `serverlessOperator.subscription.sourceNamespace` | namespace of the catalog source | `"openshift-marketplace"` |
| `rhdhOperator.enabled` | whether the operator should be deployed by the chart | `true` |
| `rhdhOperator.github.token` |  | `""` |
| `rhdhOperator.github.clientId` |  | `""` |
| `rhdhOperator.github.clientSecret` |  | `""` |
| `rhdhOperator.subscription.namespace` | namespace where the operator should be deployed | `"backstage-system"` |
| `rhdhOperator.subscription.channel` | channel of an operator package to subscribe to | `"alpha"` |
| `rhdhOperator.subscription.installPlanApproval` | whether the update should be installed automatically | `"Automatic"` |
| `rhdhOperator.subscription.pkgName` | name of the operator package | `"backstage-operator"` |
| `rhdhOperator.subscription.sourceImage` |  | `"quay.io/janus-idp/operator-catalog:0.1.0"` |
| `rhdhOperator.subscription.sourceNamespace` | namespace of the catalog source | `"openshift-marketplace"` |
| `rhdhOperator.subscription.source` | name of the catalog source for the operator | `"rhdh-operator"` |
| `postgres.serviceName` | The name of the Postgres DB service to be used by dataindex and job service. Cannot be empty. | `"sonataflow-psql-postgresql"` |
| `postgres.serviceNamespace` | The namespace of the Postgres DB service to be used by dataindex and job service. | `"sonataflow-infra"` |
| `postgres.authSecret.name` | name of existing secret to use for PostgreSQL credentials. | `"sonataflow-psql-postgresql"` |
| `postgres.authSecret.userKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-username"` |
| `postgres.authSecret.passwordKey` | name of key in existing secret to use for PostgreSQL credentials. | `"postgres-password"` |
| `postgres.database` | existing database instance used by data index and job service | `"sonataflow"` |
| `orchestrator.devmode` | devmode runs sonataflow services in ephemeral mode (for a non-production use) | `false` |
| `orchestrator.namespace` | namespace where the data index, job service and workflows are deployed | `"sonataflow-infra"` |
| `orchestrator.sonataPlatform.resources.requests.memory` |  | `"64Mi"` |
| `orchestrator.sonataPlatform.resources.requests.cpu` |  | `"250m"` |
| `orchestrator.sonataPlatform.resources.limits.memory` |  | `"1Gi"` |
| `orchestrator.sonataPlatform.resources.limits.cpu` |  | `"500m"` |
| `orchestrator.sonataPlatform.dataIndex.image` | To be removed when stable version is released | `"quay.io/kiegroup/kogito-data-index-postgresql-nightly:latest"` |
| `orchestrator.sonataPlatform.jobService.image` | To be removed when stable version is released | `"quay.io/kiegroup/kogito-jobs-service-postgresql-nightly:latest"` |
| `orchestrator.sonataflows` | workflows to get deployed - this option will be removed once the plugin will interact directly with the data-index | `[{"name": "greeting", "image": "quay.io/orchestrator/serverless-workflow-greeting:latest"}]` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

