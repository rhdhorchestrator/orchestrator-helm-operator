**Please note - this document refers to RC builds and supported by RHDH-1.2 only**, the content will be updated once plugins are released as GA.

# Prerequisites
- RHDH instance deployed with IDP configured (github, gitlab,...)
- For using the Orchestrator's [software templates](https://github.com/parodos-dev/workflow-software-templates/tree/v1.2.x), OpenShift Gitops (ArgoCD) and OpenShift Pipelines (Tekton) should be installed and configured in RHDH (to enhance the CI/CD plugins)
- A secret in RHDH's namespace name `dynamic-plugins-npmrc` that points to the plugins npm registry (details will be provided below)

# Installation steps

## Install the Orchestrator Operator
In 1.2, the Orchestrator infrastructure is being installed using the orchestrator-operator.
- Install the orchestrator-operator from the OperatorHub.
- Create orchestrator resource (operand) instance - ensure `rhdhOperator: enabled: False` is set, e.g.
  ```
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
```
cat <<EOF | oc apply -n $RHDH_NAMESPACE -f -
apiVersion: v1
data:
  .npmrc: cmVnaXN0cnk9aHR0cHM6Ly9ucG0ucmVnaXN0cnkucmVkaGF0LmNvbQo=
kind: Secret
metadata:
  name: dynamic-plugins-npmrc
  namespace: rhdh-operator
EOF
```
The value of `.data.npmrc` points to https://npm.registry.redhat.com.
For testing RC plugin versions, update to `cmVnaXN0cnk9aHR0cHM6Ly9ucG0uc3RhZ2UucmVnaXN0cnkucmVkaGF0LmNvbQo=` (points to https://npm.stage.registry.redhat.com and can be accessed internally).

### dynamic-plugins ConfigMap
This ConfigMap houses the configuration for enabling and configuring dynamic plugins. To incorporate the orchestrator plugins, append the following configuration to the **dynamic-plugins** ConfigMap:

```yaml
  - disabled: false
    package: "@redhat/backstage-plugin-orchestrator-backend-dynamic@1.1.0-rc.0-0"
    integrity: sha512-NIIGpwH/uJaMknTdORdnqsHfPeI/OrAl2biqELal1e9tK2r6PrVWfIWr9XoH5AfOjtQjbeAe7joiLwhM+uyVAw==
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow-platform-data-index-service.sonataflow-infra
  - disabled: false
    package: "@redhat/backstage-plugin-orchestrator@1.1.0-rc.0-0"
    integrity: sha512-uxkNFS/4nkVM6FRq0Uvnznvxcm/3MNdh11R6sRsbmKCP4KF4N9T2GF4lgfD7J+p7EuGMD4UFnjKjaR77v0NGaQ==
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
    package: "@redhat/plugin-signals-dynamic@0.0.5-rc.0-0"
    integrity: sha512-5Iwp9gF6VPiMLJ5NUw5s5Z17AuJ5XYS97wghNTfcmah/OFxTmgZHWxvhcRoXDRQvyj4nc/gOZes74kp6kZ9XDg==
    pluginConfig:
      dynamicPlugins:
        frontend:
          redhat.plugin-signals: {}
  - disabled: false
    package: "@redhat/plugin-notifications-backend-dynamic@0.2.0-rc.0-0"
    integrity: sha512-CHTNYVGWPxT94viabzCqxKIkDxflium9vkgh9Emu+3SuJSEsrZ6G+U1UZgpQ4gO03oOeiTm3xsoTg/AfKGf7CQ==
  - disabled: false
    package: "@redhat/plugin-signals-backend-dynamic@0.1.3-rc.0-0"
    integrity: sha512-LlkM2Mf2QTndsS6eBzyXDhJmRTHLpAku3hhlvWhtQChSLTFCtNGRTIQA5WHG7NqLH0QqBz+UcEjX7Vca82QKKg==
  - disabled: false # this plugin is optional and can be included to fan-out notifications as emails
    package: "@redhat/plugin-notifications-backend-module-email-dynamic@0.0.0-rc.0-0"
    integrity: sha512-TikxFBxBHKJYZy8go+Mw+7yjfSJILgXjr4K0C0+tnKyMOn+OqIX6K8c1fq7IdXto3fftQ+mmCrBqJem25JjVnA==
    pluginConfig:
      notifications:
         processors:
           email:
             transportConfig: # these values needs to be updated.
               transport: smtp
               hostname: my-smtp-server
               port: 587
               secure: false
               username: my-username
               password: my-password
             sender: sender@mycompany.com
             replyTo: no-reply@mycompany.com
             broadcastConfig:
               receiver: users
             concurrencyLimit: 10
             cache:
               ttl:
                 days: 1
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

### Import Orchestrator's software templates
To import the Orchestrator software templates into the catalog via the Backstage UI, follow the instructions outlined in this [document](https://backstage.io/docs/features/software-templates/adding-templates).
Register new templates into the catalog from the
- [Workflow resources (group and system)](https://github.com/parodos-dev/workflow-software-templates/blob/v1.2.x/entities/workflow-resources.yaml) (optional)
- [Basic template](https://github.com/parodos-dev/workflow-software-templates/blob/v1.2.x/scaffolder-templates/basic-workflow/template.yaml)
- [Complex template - workflow with custom Java code](https://github.com/parodos-dev/workflow-software-templates/blob/v1.2.x/scaffolder-templates/complex-assessment-workflow/template.yaml)

## Upgrade plugin versions - WIP
**NOTE** This section is still **WIP** since there are additional plugins related to the notification that haven't yet been published.

To perform an upgrade of the plugin versions, start by acquiring the new plugin version along with its associated integrity value.
In the future, this section will be updated to reference the Red Hat NPM registry. However, at present, it directs to @janus-idp NPM packages on https://registry.npmjs.com.
The following script is useful to obtain the required information for updating the plugin version:

```bash
#!/bin/bash

PLUGINS=(
  "@redhat/backstage-plugin-orchestrator"
  "@redhat/backstage-plugin-orchestrator-backend-dynamic"
  "@redhat/plugin-notifications-dynamic"
  "@redhat/plugin-notifications-backend-dynamic"
  "@redhat/plugin-notifications-backend-module-email-dynamic"
  "@redhat/plugin-signals-backend-dynamic"
  "@redhat/plugin-signals-dynamic"
)

for PLUGIN_NAME in "${PLUGINS[@]}"
do
     echo "Retriving latest version for plugin: $PLUGIN_NAME\n";
     curl -s -q "https://npm.registry.redhat.com/${PLUGIN_NAME}/" | jq -r '.versions | keys_unsorted[-1] as $latest_version | .[$latest_version] | "package: \"\(.name)@\(.version)\"\nintegrity: \(.dist.integrity)"';
     echo "---"
done
```

A sample output should look like:
```
Retriving latest version for plugin: @redhat/plugin-notifications\n
package: "@redhat/plugin-notifications@1.0.0"
integrity: sha512-t+cnwKOfqJJqbgZIMjJ1Hzr1mqHft619QoK5bF7c8TuQGUjQR0NtaIFWUNhR1JFlE4oQz0NDaAgBnDwtjMk9qA==
---
Retriving latest version for plugin: @redhat/plugin-notifications-backend-dynamic\n
package: "@redhat/plugin-notifications-backend-dynamic@1.0.0"
integrity: sha512-o4GFXmQu6uUXbCDukXHahZ37sfQQYM92pL3LhkXO5aYKudITKzlv6lEZnb9zO9Rnr3U0LD7ytFzks51EfXssXw==
---
Retriving latest version for plugin: @redhat/backstage-plugin-orchestrator\n
package: "@redhat/backstage-plugin-orchestrator@1.0.0"
integrity: sha512-CuYYR7v2O8EVoI1FA7usidzUPp1N5OOKDkIvhDRPf4I7BxgDCWLqW7rBQ4Z7qBXfpeYJrQOxInc0E2xWEat8JA==
---
Retriving latest version for plugin: @redhat/backstage-plugin-orchestrator-backend-dynamic\n
package: "@redhat/backstage-plugin-orchestrator-backend-dynamic@1.0.0"
integrity: sha512-l0g3T/a1NxX9JogTesZAdUzpNhHQaPxRwki15HWny9GlXCELAx+ta0UC3afsHy6Jp2wOn1prlW0ZuXuc7Ncb0g==
---
```

After editing the version and integrity values in the *dynamic-plugins* ConfigMap, the RHDH instance will be restarted automatically.


