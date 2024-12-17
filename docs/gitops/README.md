# Initialize the GitOps Environment

To set up the CI/CD capabilities, you can choose between two methods to install the OpenShift GitOps and OpenShift Pipelines operators.

## Method 1: Install the Operators from Demo Charts

You can use the Janus IDP Demo repository to install the `Red Hat OpenShift Pipelines` and `Red Hat OpenShift GitOps` operators. This repository contains automation scripts to install the Janus IDP Demo and its supporting components. Note that a fork of this repository has been created to remove the configuration excluding Tekton resources from being managed by ArgoCD applications. More details can be found in this [discussion](https://github.com/argoproj/argo-cd/discussions/8674#discussioncomment-2318554).

### Install OpenShift Pipelines Operator

1. Clone the repository:

    ```bash
    git clone https://github.com/rhdhorchestrator/janus-idp-bootstrap.git
    ```

2. Navigate to the charts directory:

    ```bash
    cd janus-idp-bootstrap/charts
    ```
3. Install the OpenShift Pipelines operator:

    ```bash
    helm upgrade --install orchestrator-pipelines pipelines-operator/ -f pipelines-operator/values.yaml -n orchestrator-gitops --create-namespace --set operator.channel=pipelines-1.16
    ```

### Install OpenShift GitOps Operator

1. Install and configure the OpenShift GitOps operator:

    ```bash
    helm upgrade --install orchestrator-gitops gitops-operator/ -f gitops-operator/values.yaml -n orchestrator-gitops --create-namespace --set namespaces={orchestrator-gitops}
    ```


## Method 2: Install the Operators from OpenShift OperatorHub

### Install OpenShift Pipelines Operator

The OpenShift Pipelines Operator can be installed directly from the OperatorHub. Select the operator from the list and install it without any special configuration.

### Install OpenShift GitOps Operator

To install the OpenShift GitOps Operator with custom configuration:

1. Add the following configuration to the Subscription used to install the operator:

    ```yaml
    config:
      env:
      - name: DISABLE_DEFAULT_ARGOCD_INSTANCE
        value: "true"
      - name: ARGOCD_CLUSTER_CONFIG_NAMESPACES
        value: "orchestrator-gitops"
    ```

    Detailed information about these environment variables can be found in the [OpenShift GitOps Usage Guide](https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#installation-of-openshift-gitops-without-ready-to-use-argo-cd-instance-for-rosaosd) and the [ArgoCD Operator Documentation](https://argocd-operator.readthedocs.io/en/latest/usage/basics/#cluster-scoped-instance).

2. Create an ArgoCD instance in the `orchestrator-gitops` namespace:

    ```bash
    oc new-project orchestrator-gitops
    oc apply -f https://raw.githubusercontent.com/rhdhorchestrator/orchestrator-helm-operator/main/docs/gitops/resources/argocd-example.yaml
    ```

    Alternatively, if creating a default ArgoCD instance, ensure to exclude Tekton resources from its specification:

    ```yaml
    resourceExclusions: |
      - apiGroups:
        - tekton.dev
        clusters:
        - '*'
        kinds:
        - TaskRun
        - PipelineRun
    ```

3. Add a label to the workflow namespace (`sonataflow-infra`) to enable ArgoCD to manage resources in that namespace:

    ```bash
    oc label ns sonataflow-infra argocd.argoproj.io/managed-by=orchestrator-gitops
    ```

These steps will set up the required CI/CD environment using either method. Ensure to follow the steps carefully to achieve a successful installation.

## Installing docker credentials

The Tekton pipeline deployed by the Orchestrator is responsible for building a workflow image and pushing it to Quay.io.
There is a need to create a single K8s secret combined with the following secrets:
1. A secret for Quay.io organization to push the images built by the pipeline:
   - Create or edit a [Robot account](https://access.redhat.com/documentation/en-us/red_hat_quay/3.3/html/use_red_hat_quay/use-quay-manage-repo) and grant it `Write` permissions to the newly created repository
   - Download the credentials as Kubernetes secret.
2. A secret for _registry.redhat.io_. To build workflow images, the pipeline uses the [builder image](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/pipeline/workflow-builder.Dockerfile) from [registry.redhat.io](https://registry.redhat.io).
   - Generate a token [here](https://access.redhat.com/terms-based-registry/create), and download it as OCP secret.

Those two K8s secrets should be merged into a single secret named `docker-credentials` in `orchestrator-gitops` namespace in the cluster that runs the pipelines.
You may use this [helper script](https://github.com/rhdhorchestrator/orchestrator-helm-operator/blob/main/hack/merge_secrets.sh) to merge the secrets or choose another method of downloading the credentials and merging them.

## Define the SSH credentials

The pipeline uses SSH to push the deployment configuration to the `gitops` repository containing the `kustomize` deployment configuration.

Follow these steps to properly configure the credentials in the namespace:

- Generate default SSH keys under the `ssh` folder

```console
mkdir -p ssh
ssh-keygen -t rsa -b 4096 -f ssh/id_rsa -N "" -C git@github.com -q
```

- Add the SSH key to your GitHub account using the gh CLI or using the [SSH keys](https://github.com/settings/keys) setting:

```console
gh ssh-key add ssh/id_rsa.pub --title "Tekton pipeline"
```

- Create a `known_hosts` file by scanning the GitHub's SSH public key:

```console
ssh-keyscan github.com > ssh/known_hosts
```

- Create the default `config` file:

```console
echo "Host github.com
  HostName github.com
  IdentityFile ~/.ssh/id_rsa" > ssh/config
```

- Create the secret that the Pipeline uses to store the SSH credentials:

```console
oc create secret -n orchestrator-gitops generic git-ssh-credentials \
  --from-file=ssh/id_rsa \
  --from-file=ssh/config \
  --from-file=ssh/known_hosts
```

Note: if you change the SSH key type from the default value `rsa`, you need to update the `config` file accordingly

## Setting up GitHub Integration

To begin serverless workflow development using the "Basic workflow bootstrap project" software template with GitHub as the target source control, you'll need to configure organization settings to allow read and write permissions for GitHub workflows. Follow these steps to enable the necessary permissions:

1. Navigate to your organization settings on GitHub.
2. Locate the section for managing organization settings related to GitHub Actions.
3. Enable read and write permissions for workflows by adjusting the settings accordingly.
4. For detailed instructions and exact steps, refer to the GitHub guide available [here](https://docs.github.com/en/enterprise-server@3.9/organizations/managing-organization-settings/disabling-or-limiting-github-actions-for-your-organization#configuring-the-default-github_token-permissions).
