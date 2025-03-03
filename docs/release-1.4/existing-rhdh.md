# Prerequisites
- RHDH 1.4 instance deployed with IDP configured (github, gitlab, ...)
- For using the Orchestrator's [software templates](https://github.com/rhdhorchestrator/workflow-software-templates/tree/v1.4.x), OpenShift GitOps (ArgoCD) and OpenShift Pipelines (Tekton) should be installed and configured in RHDH (to enhance the CI/CD plugins) - [Follow these steps](https://github.com/rhdhorchestrator/orchestrator-helm-operator/blob/main/docs/gitops/README.md)
- A secret in RHDH's namespace named `dynamic-plugins-npmrc` that points to the plugins npm registry (details will be provided below)

# Installation steps

## Install the Orchestrator Operator
In 1.4, the Orchestrator infrastructure is installed using the Orchestrator Operator.
1. Install the Orchestrator Operator 1.4 from OperatorHub.
1. Create orchestrator resource (operand) instance - ensure `rhdhOperator: enabled: False` is set, e.g.
    > Note: `${TARGET_NAMESPACE}` should be set to the desired namespace

    ```yaml
    apiVersion: rhdh.redhat.com/v1alpha1
    kind: Orchestrator
    metadata:
      name: orchestrator-sample
      namespace: ${TARGET_NAMESPACE}    # Replace with desired namespace
    spec:
      orchestrator:
        namespace: sonataflow-infra
        sonataflowPlatform:
          resources:
            limits:
              cpu: 500m
              memory: 1Gi
            requests:
              cpu: 250m
              memory: 64Mi
      postgres:
        authSecret:
          name: sonataflow-psql-postgresql
          passwordKey: postgres-password
          userKey: postgres-username
        database: sonataflow
        serviceName: sonataflow-psql-postgresql
        serviceNamespace: sonataflow-infra
      rhdhOperator:
        enabled: false
      networkPolicy:
        rhdhNamespace: ${RHDH_NAMESPACE} # Replace with namespace RHDH is deployed in
    ```
1. Verify resources and wait until they are running
   1. From the console run the following command in order to get the necessary wait commands: \
      `oc describe orchestrator orchestrator-sample -n ${TARGET_NAMESPACE} | grep -A 10 "Run the following commands to wait until the services are ready:"`

      The command will return an output similar to the one below, which lists several oc wait commands. This depends on your specific cluster.
      ```bash
        oc wait -n openshift-serverless deploy/knative-openshift --for=condition=Available --timeout=5m
        oc wait -n knative-eventing knativeeventing/knative-eventing --for=condition=Ready --timeout=5m
        oc wait -n knative-serving knativeserving/knative-serving --for=condition=Ready --timeout=5m
        oc wait -n openshift-serverless-logic deploy/logic-operator-rhel8-controller-manager --for=condition=Available --timeout=5m
        oc wait -n sonataflow-infra sonataflowplatform/sonataflow-platform --for=condition=Succeed --timeout=5m
        oc wait -n sonataflow-infra deploy/sonataflow-platform-data-index-service --for=condition=Available --timeout=5m
        oc wait -n sonataflow-infra deploy/sonataflow-platform-jobs-service --for=condition=Available --timeout=5m
        oc get networkpolicy -n sonataflow-infra
        ```
   1. Copy and execute each command from the output in your terminal. These commands ensure that all necessary services and resources in your OpenShift environment are available and running correctly.
   1. If any service does not become available, verify the logs for that service or consult [troubleshooting steps](https://www.rhdhorchestrator.io/main/docs/serverless-workflows/troubleshooting/).

## Edit RHDH configuration
As part of RHDH deployed resources, there are two primary ConfigMaps that require modification, typically found under the *rhdh-operator* namespace, or located in the same namespace as the Backstage CR.
Before enabling the Orchestrator and Notifications plugins, please ensure that a secret that points to the target npmjs registry exists in the same RHDH namespace, e.g.:
```
cat <<EOF | oc apply -n $RHDH_NAMESPACE -f -
apiVersion: v1
data:
  .npmrc: cmVnaXN0cnk9aHR0cHM6Ly9ucG0ucmVnaXN0cnkucmVkaGF0LmNvbQo=
kind: Secret
metadata:
  name: dynamic-plugins-npmrc
EOF
```
The value of `.data.npmrc` in the above example points to https://npm.registry.redhat.com. It should be included to consume plugins referenced in this document. If including plugins
from a different NPM registry, the `.data.npmrc` value should be updated with the base64 encoded NPM registry. Example: https://registry.npmjs.org would be `aHR0cHM6Ly9yZWdpc3RyeS5ucG1qcy5vcmcK`.

If there is a need to point to multiple registries, modify the content of the secret's data from:

```yaml
  stringData:
    .npmrc: |
      registry=https://npm.registry.redhat.com
```
to
```yaml
  stringData:
    .npmrc: |
      @redhat:registry=https://npm.registry.redhat.com
      @<other-scope>:registry=<other-registry>
```

### Proxy configuration

If you configured a proxy in your RHDH instance then you need to edit the `NO_PROXY` configuration. You need to add the namespaces where the workflows are deployed and also the namespace `sonataflow-infra`. E.g. NO_PROXY=current-value-of-no-proxy, `.sonataflow-infra`,`.my-workflow-names
pace`. Note the `.` before the namespace name.

### dynamic-plugins ConfigMap
This ConfigMap houses the configuration for enabling and configuring dynamic plugins in RHDH.

To incorporate the Orchestrator plugins, append the following configuration to the **dynamic-plugins** ConfigMap:

- Be sure to review [this section](#identify-latest-supported-plugin-versions) to determine the latest supported Orchestrator plugin `package:` and `integrity:` values, and update the dynamic-plugin ConfigMap entries accordingly. The samples in this document may not reflect the latest.
- Additionally, ensure that the `dataIndexService.url` in the below configuration points to the service of the Data Index installed by the Orchestrator Operator.
By default it should point to `http://sonataflow-platform-data-index-service.sonataflow-infra`. Confirm the service by running this command:
  ```bash
  oc get svc -n sonataflow-infra sonataflow-platform-data-index-service -o jsonpath='http://{.metadata.name}.{.metadata.namespace}'
  ```
```yaml
      - disabled: false
        package: "https://github.com/rhdhorchestrator/orchestrator-plugins-internal-release/releases/download/1.4.0/backstage-plugin-orchestrator-backend-dynamic-1.4.0.tgz"
        integrity: sha512-2aOHDLFrGMAtyHFiyGZwVBZ9Op+TmKYUwfZxwoaGJ1s6JSy/0qgqineEEE0K3dn/f17XBUj+H1dwa5Al598Ugw==
        pluginConfig:
          orchestrator:
            dataIndexService:
              url: http://sonataflow-platform-data-index-service.sonataflow-infra
      - disabled: false
        package: "https://github.com/rhdhorchestrator/orchestrator-plugins-internal-release/releases/download/1.4.0/backstage-plugin-orchestrator-1.4.0.tgz"
        integrity: sha512-2yasbfBZ3iKntArIfK+hk9tvv4b/dy9+WKXOcWIotqkI1gv+Nhvy+m55KAUWi2vmfM0rj3EoG6YP+3Zajn1KyA==
        pluginConfig:
          dynamicPlugins:
            frontend:
              red-hat-developer-hub.backstage-plugin-orchestrator:
                appIcons:
                  - importName: OrchestratorIcon
                    module: OrchestratorPlugin
                    name: orchestratorIcon
                dynamicRoutes:
                  - importName: OrchestratorPage
                    menuItem:
                      icon: orchestratorIcon
                      text: Orchestrator
                    module: OrchestratorPlugin
                    path: /orchestrator
```

To include the Notification Plugin append this configuration to the ConfigMap:
- Be sure to review [this section](#identify-latest-supported-plugin-versions) to determine the latest supported Orchestrator plugin `package:` and `integrity:` values, and update the dynamic-plugin ConfigMap entries accordingly. The samples in this document may not reflect the latest.
```yaml
      - disabled: false
        package: "./dynamic-plugins/dist/backstage-plugin-notifications"
      - disabled: false
        package: "./dynamic-plugins/dist/backstage-plugin-signals"
      - disabled: false
        package: "./dynamic-plugins/dist/backstage-plugin-notifications-backend-dynamic"
      - disabled: false
        package: "./dynamic-plugins/dist/backstage-plugin-signals-backend-dynamic"
```

Optionally, include the `plugin-notifications-backend-module-email-dynamic` to fan-out notifications as emails.
The environment variables below need to be provided to the RHDH instance (Or set the values directly in the ConfigMap).
See more configuration options for the plugin [here](https://github.com/backstage/backstage/blob/master/plugins/notifications-backend-module-email/config.d.ts).
```yaml
      - disabled: false
        package: "./dynamic-plugins/dist/backstage-plugin-notifications-backend-module-email-dynamic"
        pluginConfig:
          notifications:
            processors:
              email:
                transportConfig:
                  transport: smtp
                  hostname: ${NOTIFICATIONS_EMAIL_HOSTNAME}   # Use value or make variable accessible to Backstage
                  port: 587
                  secure: false
                  username: ${NOTIFICATIONS_EMAIL_USERNAME}   # Use value or make variable accessible to Backstage
                  password: ${NOTIFICATIONS_EMAIL_PASSWORD}   # Use value or make variable accessible to Backstage
                sender: sender@mycompany.com
                replyTo: no-reply@mycompany.com
                broadcastConfig:
                  receiver: "none"
                concurrencyLimit: 10
                cache:
                  ttl:
                    days: 1
```

Include ArgoCD and Tekton Plugins if using OpenShift Gitops (ArgoCD) and OpenShift Pipelines (Tekton) for Orchestrator Workflows
```yaml
      - disabled: false
        package: ./dynamic-plugins/dist/backstage-community-plugin-tekton
      - disabled: false
        package: ./dynamic-plugins/dist/backstage-community-plugin-redhat-argocd
      - disabled: false
        package: ./dynamic-plugins/dist/roadiehq-backstage-plugin-argo-cd-backend-dynamic
      - disabled: false
        package: ./dynamic-plugins/dist/roadiehq-scaffolder-backend-argocd-dynamic
      - disabled: false
        package: ./dynamic-plugins/dist/backstage-plugin-kubernetes-backend-dynamic
        pluginConfig:
          kubernetes:
            clusterLocatorMethods:
            - clusters:
              - authProvider: serviceAccount
                name: Default Cluster
                serviceAccountToken: ${K8S_CLUSTER_TOKEN}
                skipTLSVerify: true
                url: ${K8S_CLUSTER_URL}
              type: config
            customResources:
            - apiVersion: v1
              group: tekton.dev
              plural: pipelines
            - apiVersion: v1
              group: tekton.dev
              plural: pipelineruns
            - apiVersion: v1
              group: tekton.dev
              plural: taskruns
            - apiVersion: v1
              group: route.openshift.io
              plural: routes
            serviceLocatorMethod:
              type: multiTenant
      - disabled: false
        package: ./dynamic-plugins/dist/backstage-plugin-kubernetes
      - disabled: false
        package: ./dynamic-plugins/dist/backstage-plugin-scaffolder-backend-module-github-dynamic
```

### app-config ConfigMap
This ConfigMap is used for configuring backstage. Please add/modify to include the following:
- `${BACKEND_SECRET}` A static access token to enable the workflows to send notifications to RHDH (As described in the example below) or to invoke scaffolder actions (Or a different method based on this [doc](https://backstage.io/docs/auth/service-to-service-auth/)).
- A static access token can be generated with this command `node -p 'require("crypto").randomBytes(24).toString("base64")'`
- `${RHDH_ROUTE}` can be determined by running `oc get route -A -l app.kubernetes.io/name=backstage`
- Define csp and cors
- The `guest` provider is used in this example because backstage requires at least one provider to start (It is not required for Orchestrator). The guest provider should only be used for development purposes.
```yaml
    auth:
      environment: development
      providers:
        guest:
          dangerouslyAllowOutsideDevelopment: true
    backend:
      auth:
        externalAccess:
          - type: static
            options:
              token: ${BACKEND_SECRET} # Use value or make variable accessible to Backstage
              subject: orchestrator
          - type: legacy
            options:
              subject: legacy-default-config
              secret: "pl4s3Ch4ng3M3"
      baseUrl: https://${RHDH_ROUTE} # Use value or make variable accessible to Backstage
      csp:
        script-src: ["'self'", "'unsafe-inline'", "'unsafe-eval'"]
        script-src-elem: ["'self'", "'unsafe-inline'", "'unsafe-eval'"]
        connect-src: ["'self'", 'http:', 'https:', 'data:']
      cors:
        origin: https://${RHDH_ROUTE} # Use value or make variable accessible to Backstage
      # Include the database configuration if using the notifications plugin
      database:
        client: pg
        connection:
          password: ${POSTGRESQL_ADMIN_PASSWORD}
          user: ${POSTGRES_USER}
          host: ${POSTGRES_HOST}
          port: ${POSTGRES_PORT}
```
> Note: `${BACKEND_SECRET}` and `${RHDH_ROUTE}` variables are not by default accessible by Backstage, so the values should be used directly in the ConfigMap or made accessible to Backstage.
The `${POSTGRES_*}` variables *are* accessible by default, so they can be left in variable form.

### Import Orchestrator's software templates
Orchestrator software templates rely on the following tools:
- Github or GitLab as the git repository system
- Quay is the image registry
- GitOps tools are OpenShift GitOps (ArgoCD) and OpenShift Pipelines (Tekton)

To import the Orchestrator software templates into the catalog via the Backstage UI, follow the instructions outlined in this [document](https://backstage.io/docs/features/software-templates/adding-templates).
Register new templates into the catalog from the
- Software templates for GitHub:
  - [Basic template](https://github.com/rhdhorchestrator/workflow-software-templates/blob/v1.4.x/scaffolder-templates/github-workflows/basic-workflow/template.yaml)
  - [Advanced template - workflow with custom Java code](https://github.com/rhdhorchestrator/workflow-software-templates/blob/v1.4.x/scaffolder-templates/github-workflows/advanced-workflow/template.yaml)
- Software templates for GitLab:
  - [Basic template](https://github.com/rhdhorchestrator/workflow-software-templates/blob/v1.4.x/scaffolder-templates/gitlab-workflows/basic-workflow/template.yaml)
  - [Advanced template - workflow with custom Java code](https://github.com/rhdhorchestrator/workflow-software-templates/blob/v1.4.x/scaffolder-templates/gitlab-workflows/advanced-workflow/template.yaml)
- [Workflow resources (group and system)](https://github.com/rhdhorchestrator/workflow-software-templates/blob/v1.4.x/entities/workflow-resources.yaml) (optional)

## Plugin Versions

### Identify Latest Supported Plugin Versions
The versions of the plugins may undergo updates, leading to changes in their integrity values. The default plugin values in the Orchestrator CRD can be referenced to ensure that the latest supported plugin versions and integrity values are being utilized. The Orchestrator CRD default plugins can be identified with this command:
```bash
oc get crd orchestrators.rhdh.redhat.com -o json | jq '.spec.versions[].schema.openAPIV3Schema.properties.spec.properties.rhdhPlugins.properties'
```

In the example output below, `.properties.integrity.default` is the integrity value and `.properties.package.default` is the package name:
```yaml
  "orchestratorBackend": {
    "description": "Orchestrator backend plugin information",
    "properties": {
      "integrity": {
        "default": "sha512-2aOHDLFrGMAtyHFiyGZwVBZ9Op+TmKYUwfZxwoaGJ1s6JSy/0qgqineEEE0K3dn/f17XBUj+H1dwa5Al598Ugw==",
        "description": "Package SHA integrity",
        "type": "string"
      },
      "package": {
        "default": "backstage-plugin-orchestrator-backend-dynamic@1.4.0",
        "description": "Package name",
        "type": "string"
      }
    },
    "type": "object"
  },
```
> Note: The Orchestrator plugin package names in the `dynamic-plugins` ConfigMap must have `@redhat/` prepended to the package name (i.e., `@redhat/backstage-plugin-orchestrator-backend-dynamic@1.4.0`)

### Upgrade plugin versions - WIP
To perform an upgrade of the plugin versions, start by acquiring the new plugin version along with its associated integrity value.
The following script is useful to obtain the required information for updating the plugin version, however, make sure to select plugin version compatible with the Orchestrator operator version (e.g. 1.4.x for both operator and plugins).

> Note: It is recommended to use the Orchestrator Operator default plugins

```bash
#!/bin/bash

PLUGINS=(
  "@redhat/backstage-plugin-orchestrator"
  "@redhat/backstage-plugin-orchestrator-backend-dynamic"
)

for PLUGIN_NAME in "${PLUGINS[@]}"
do
     echo "Retrieving latest version for plugin: $PLUGIN_NAME\n";
     curl -s -q "https://npm.registry.redhat.com/${PLUGIN_NAME}/" | jq -r '.versions | keys_unsorted[-1] as $latest_version | .[$latest_version] | "package: \"\(.name)@\(.version)\"\nintegrity: \(.dist.integrity)"';
     echo "---"
done
```

A sample output should look like:
```
Retrieving latest version for plugin: @redhat/backstage-plugin-orchestrator\n
package: "@redhat/backstage-plugin-orchestrator@1.4.0"
integrity: sha512-vGGd9hUmDriEMmP2TfzLVa3JSnfot2Blg+aftDnu/lEphsY1s2gdA4Z5lCxUk7aobcKE6JO/f0sIl2jyxZ7ktw==
---
Retrieving latest version for plugin: @redhat/backstage-plugin-orchestrator-backend-dynamic\n
package: "@redhat/backstage-plugin-orchestrator-backend-dynamic@1.4.0"
integrity: sha512-tS5cJGwjzP9esdTZvUFjw0O7+w9gGBI/+VvJrtqYJBDGXcEAq9iYixGk67ddQVW5eeUM7Tk1WqJlNj282aAWww==
---
```

After editing the version and integrity values in the *dynamic-plugins* ConfigMap, the RHDH instance will be restarted automatically.
