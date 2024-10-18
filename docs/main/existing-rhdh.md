# Prerequisites
Before proceeding, ensure the following prerequisites are in place:
1. **RHDH instance**\
RHDH instance deployed with IDP configured (github, gitlab,...)
1. **Secret for npm registry**\
A secret in RHDH's namespace name `dynamic-plugins-npmrc` that points to the plugins npm registry (details will be provided below)
1. **PostgreSQL Database**\
A PostgreSQL database is mandatory for the Orchestrator's operations.
You have two options for meeting this requirement:\
   - **If you do not have a PostgreSQL instance in your cluster** \
   you can deploy the PostgreSQL reference implementation by following the steps here.
   - **If you already have PostgreSQL running in your cluster** \
   ensure that the default settings in the [PostgreSQL values](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/postgresql/values.yaml) file match those provided in the [Orchestrator values](https://github.com/parodos-dev/orchestrator-helm-chart/blob/main/charts/orchestrator/values.yaml) file.

><font color="red">⚠️**Warning**:</font> Skipping these steps will prevent the Orchestrator from functioning properly. 

## For Software template
1. **OpenShift Gitops (ArgoCD) and OpenShift Pipelines (Tekton)**\
For using the Orchestrator's [software templates](https://github.com/parodos-dev/workflow-software-templates/tree/v1.2.x), OpenShift Gitops (ArgoCD) and OpenShift Pipelines (Tekton) should be installed and configured in RHDH (to enhance the CI/CD plugins)

# Installation steps

## Install the Orchestrator Operator
In 1.2, the Orchestrator infrastructure is being installed using the orchestrator-operator.
1. Install Orchestrator operator
   1. Go to OperatorHub in your OpenShift Console.
   1. Search for and install the Orchestrator Operator.
1. Create an Orchestrator instance
   1. Once the Orchestrator Operator is installed, navigate to Installed Operators.
   1. Select Orchestrator Operator.
   2. Click on Create Instance to deploy an Orchestrator instance but edit the YAML defintion disabling RHDH operator by setting `rhdhOperator: enabled: False`, e.g.
  ```yaml
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
  ```

## Edit RHDH configuration
As part of RHDH deployed resources, there are two primary ConfigMaps that require modification, typically found under the *rhdh-operator* namespaces, or located in the same namespace as the Backstage CR.
Before enabling the Orchestrator and Notifications plugins, pls ensure a secret that points to the target npmjs registry exists in the same RHDH namespace, e.g.:
```bash
cat <<EOF | oc apply -n $RHDH_NAMESPACE -f -
apiVersion: v1
data:
  .npmrc: cmVnaXN0cnk9aHR0cHM6Ly9ucG0ucmVnaXN0cnkucmVkaGF0LmNvbQo=
kind: Secret
metadata:
  name: dynamic-plugins-npmrc
EOF
```
The value of `.data.npmrc` points to https://npm.registry.redhat.com.
For testing RC plugin versions, update to `cmVnaXN0cnk9aHR0cHM6Ly9ucG0uc3RhZ2UucmVnaXN0cnkucmVkaGF0LmNvbQo=` (points to https://npm.stage.registry.redhat.com and can be accessed internally). If there is a need to point to multiple registries, modify the content of the secret's data from:
```
  stringData:
    .npmrc: |
      registry=https://npm.registry.redhat.com
```
to
```
  stringData:
    .npmrc: |
      @redhat:registry=https://npm.registry.redhat.com
      @<other-scope>:registry=<other-registry>
```

### dynamic-plugins ConfigMap
This ConfigMap houses the configuration for enabling and configuring dynamic plugins. To incorporate the orchestrator plugins, in the **dynamic-plugins** ConfigMap append into `plugins` section the following configuration:

```yaml
  - disabled: false
    package: "@redhat/backstage-plugin-orchestrator-backend-dynamic@1.2.0"
    integrity: sha512-lyw7IHuXsakTa5Pok8S2GK0imqrmXe3z+TcL7eB2sJYFqQPkCP5la1vqteL9/1EaI5eI6nKZ60WVRkPEldKBTg==
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow-platform-data-index-service.sonataflow-infra
  - disabled: false
    package: "@redhat/backstage-plugin-orchestrator@1.2.0"
    integrity: sha512-FhM13wVXjjF39syowc4RnMC/gKm4TRlmh8lBrMwPXAw1VzgIADI8H6WVEs837poVX/tYSqj2WhehwzFqU6PuhA==
    pluginConfig:
      dynamicPlugins:
        frontend:
          janus-idp.backstage-plugin-orchestrator:
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

The versions of the plugins may undergo updates, leading to changes in their integrity values. To ensure you are utilizing the latest versions, please consult the values available [here](https://github.com/parodos-dev/orchestrator-helm-operator/blob/main/helm-charts/orchestrator/values.yaml). It's imperative to set both the version and integrity values accordingly.

Additionally, ensure that the `dataIndexService.url` points to the service of the Data Index installed by the Chart/Operator.
When installed by the Helm chart, it should point to `http://sonataflow-platform-data-index-service.sonataflow-infra`:
```bash
oc get svc -n sonataflow-infra sonataflow-platform-data-index-service -o jsonpath='http://{.metadata.name}.{.metadata.namespace}'
```

### app-config ConfigMap
This ConfigMap used for configuring backstage. Please add/modify to include the following:
- A static access token (or a different method based on this [doc](https://backstage.io/docs/auth/service-to-service-auth/) to enable the workflows to send notifications to RHDH or to invoke scaffolder actions.
- Define csp and cors

```yaml
app:
  backend:
    auth:
      externalAccess:
        - type: static
          options:
            token: ${BACKEND_SECRET}
            subject: orchestrator
    csp:
      script-src: ["'self'", "'unsafe-inline'", "'unsafe-eval'"]
      script-src-elem: ["'self'", "'unsafe-inline'", "'unsafe-eval'"]
      connect-src: ["'self'", 'http:', 'https:', 'data:']
    cors:
      origin: {{ URL to RHDH service or route }}
```

To enable the Notifications plugin, edit the same ConfigMaps.
For the `dynamic-plugins` ConfigMap add:
```yaml
  - disabled: false
    package: "@redhat/plugin-notifications-dynamic@0.2.0-rc.0-0"
    integrity: sha512-wmISWN02G4OiBF7y8Jpl5KCbDfhzl70s+r0h2tdVh1IIwYmojH5pqXFQAhDd3FTlqYc8yqDG8gEAQ8v66qbU1g==
    pluginConfig:
      dynamicPlugins:
        frontend:
          redhat.plugin-notifications:
            dynamicRoutes:
              - importName: NotificationsPage
                menuItem:
                  config:
                    props:
                      titleCounterEnabled: true
                      webNotificationsEnabled: false
                  importName: NotificationsSidebarItem
                path: /notifications
  - disabled: false
    package: "@redhat/plugin-notifications-dynamic@1.2.0"
    integrity: sha512-1mhUl14v+x0Ta1o8Sp4KBa02izGXHd+wsiCVsDP/th6yWDFJsfSMf/DyMIn1Uhat1rQgVFRUMg8QgrvbgZCR/w==
    pluginConfig:
      dynamicPlugins:
        frontend:
          redhat.plugin-signals: {}
  - disabled: false
    package: "@redhat/plugin-notifications-backend-dynamic@1.2.0"
    integrity: sha512-pCFB/jZIG/Ip1wp67G0ZDJPp63E+aw66TX1rPiuSAbGSn+Mcnl8g+XlHLOMMTz+NPloHwj2/Tp4fSf59w/IOSw==
  - disabled: false
    package: "@redhat/plugin-signals-backend-dynamic@1.2.0"
    integrity: sha512-DIISzxtjeJ4a9mX3TLcuGcavRHbCtQ5b52wHn+9+uENUL2IDbFoqmB4/9BQASaKIUSFkRKLYpc5doIkrnTVyrA==
```

For the `*-app-config` ConfigMap add the database configuration if isn't already provided. It is required for the notifications plugin:
```yaml
    app:
      title: Red Hat Developer Hub
      baseUrl: {{ URL to RHDH service or route }}
    backend:
      database:
        client: pg
        connection:
          password: ${POSTGRESQL_ADMIN_PASSWORD}
          user: ${POSTGRES_USER}
          host: ${POSTGRES_HOST}
          port: ${POSTGRES_PORT}
```
If persistence is enabled (which should be the default setting), ensure that the PostgreSQL environment variables are accessible.
The RHDH instance will be restarted automatically on ConfigMap changes.

Optionally, include the plugin-notifications-backend-module-email-dynamic to fan-out notifications as emails.
The environment variables below need to be provided to the RHDH instance.
See more configuration options for the plugin [here](https://github.com/backstage/backstage/blob/master/plugins/notifications-backend-module-email/config.d.ts).
```
- disabled: false # 
    package: "@redhat/plugin-notifications-backend-module-email-dynamic@1.2.0"
    integrity: sha512-dtmliahV5+xtqvwdxP2jvyzd5oXTbv6lvS3c9nR8suqxTullxxj0GFg1uU2SQ2uKBQWhOz8YhSmrRwxxLa9Zqg==
    pluginConfig:
      notifications:
         processors:
           email:
             transportConfig: # these values needs to be updated.
               transport: smtp
               hostname: ${NOTIFICATIONS_EMAIL_HOSTNAME}
               port: 587
               secure: false
               username: ${NOTIFICATIONS_EMAIL_USERNAME}
               password: ${NOTIFICATIONS_EMAIL_PASSWORD}
             sender: sender@mycompany.com
             replyTo: no-reply@mycompany.com
             broadcastConfig:
               receiver: "none"
             concurrencyLimit: 10
             cache:
               ttl:
                 days: 1
```

### Import Orchestrator's software templates
To import the Orchestrator software templates into the catalog via the Backstage UI, follow the instructions outlined in this [document](https://backstage.io/docs/features/software-templates/adding-templates).
Register new templates into the catalog from the
- [Workflow resources (group and system)](https://github.com/parodos-dev/workflow-software-templates/blob/v1.2.x/entities/workflow-resources.yaml) (optional)
- [Basic template](https://github.com/parodos-dev/workflow-software-templates/blob/v1.2.x/scaffolder-templates/basic-workflow/template.yaml)
- [Complex template - workflow with custom Java code](https://github.com/parodos-dev/workflow-software-templates/blob/v1.2.x/scaffolder-templates/complex-assessment-workflow/template.yaml)

## Upgrade plugin versions - WIP
To perform an upgrade of the plugin versions, start by acquiring the new plugin version along with its associated integrity value.
The following script is useful to obtain the required information for updating the plugin version, however, make sure to select plugin version compatible with the Orchestrator operator version (e.g. 1.2.x for both operator and plugins).

```bash
#!/bin/bash

PLUGINS=(
  "@redhat/backstage-plugin-orchestrator"
  "@redhat/backstage-plugin-orchestrator-backend-dynamic"
  "@redhat/plugin-notifications-dynamic"
  "@redhat/plugin-notifications-backend-dynamic"
  "@redhat/plugin-signals-dynamic"
  "@redhat/plugin-signals-backend-dynamic"
  "@redhat/plugin-notifications-backend-module-email-dynamic"
)

for PLUGIN_NAME in "${PLUGINS[@]}"
do
     echo "Retriving latest version for plugin: $PLUGIN_NAME\n";
     curl -s -q "https://npm.registry.redhat.com/${PLUGIN_NAME}/" | jq -r '.versions | keys_unsorted[-1] as $latest_version | .[$latest_version] | "package: \"\(.name)@\(.version)\"\nintegrity: \(.dist.integrity)"';
     echo "---"
done
```

A sample output should look like:
Retriving latest version for plugin: @redhat/backstage-plugin-orchestrator\n
package: "@redhat/backstage-plugin-orchestrator@1.2.0"
integrity: sha512-FhM13wVXjjF39syowc4RnMC/gKm4TRlmh8lBrMwPXAw1VzgIADI8H6WVEs837poVX/tYSqj2WhehwzFqU6PuhA==
---
Retriving latest version for plugin: @redhat/backstage-plugin-orchestrator-backend-dynamic\n
package: "@redhat/backstage-plugin-orchestrator-backend-dynamic@1.2.0"
integrity: sha512-lyw7IHuXsakTa5Pok8S2GK0imqrmXe3z+TcL7eB2sJYFqQPkCP5la1vqteL9/1EaI5eI6nKZ60WVRkPEldKBTg==
---
Retriving latest version for plugin: @redhat/plugin-notifications-dynamic\n
package: "@redhat/plugin-notifications-dynamic@1.2.0"
integrity: sha512-1mhUl14v+x0Ta1o8Sp4KBa02izGXHd+wsiCVsDP/th6yWDFJsfSMf/DyMIn1Uhat1rQgVFRUMg8QgrvbgZCR/w==
---
Retriving latest version for plugin: @redhat/plugin-notifications-backend-dynamic\n
package: "@redhat/plugin-notifications-backend-dynamic@1.2.0"
integrity: sha512-pCFB/jZIG/Ip1wp67G0ZDJPp63E+aw66TX1rPiuSAbGSn+Mcnl8g+XlHLOMMTz+NPloHwj2/Tp4fSf59w/IOSw==
---
Retriving latest version for plugin: @redhat/plugin-notifications-backend-module-email-dynamic\n
package: "@redhat/plugin-notifications-backend-module-email-dynamic@1.2.0"
integrity: sha512-dtmliahV5+xtqvwdxP2jvyzd5oXTbv6lvS3c9nR8suqxTullxxj0GFg1uU2SQ2uKBQWhOz8YhSmrRwxxLa9Zqg==
---
Retriving latest version for plugin: @redhat/plugin-signals-backend-dynamic\n
package: "@redhat/plugin-signals-backend-dynamic@1.2.0"
integrity: sha512-DIISzxtjeJ4a9mX3TLcuGcavRHbCtQ5b52wHn+9+uENUL2IDbFoqmB4/9BQASaKIUSFkRKLYpc5doIkrnTVyrA==
---
Retriving latest version for plugin: @redhat/plugin-signals-dynamic\n
package: "@redhat/plugin-signals-dynamic@1.2.0"
integrity: sha512-5tbZyRob0JDdrI97HXb7JqFIzNho1l7JuIkob66J+ZMAPCit+pjN1CUuPbpcglKyyIzULxq63jMBWONxcqNSXw==
---

After editing the version and integrity values in the *dynamic-plugins* ConfigMap, the RHDH instance will be restarted automatically.


