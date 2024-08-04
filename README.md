# orchestrator-helm-operator
Meta Operator for deploying the Orchestrator helm charts

# Pre-install requirements
This operator is a helm operator using the helm charts from the orchestrator repository. As such, you need to fulfill the pre-install requirements defined in the [README.md](https://github.com/parodos-dev/orchestrator-helm-chart/blob/gh-pages/README.md) prior to deploying the operator in a cluster.

## Release

Follow these steps to release a new version of the operator:

1. Pull a fresh copy of the repository. Alternatively pull the latest from main on your existing repository and ensure that the HEAD matches the upstream's HEAD commit hash.
2. Create a new branch, example `release/1.2.0-rc7`.
3. Delete the contents of `helm-charts`. Deleting the contents ensures that any file removed in the latest version of the helm chart will no longer exist in the operator's copy of the helm charts.
4. Copy the contents of the `charts/orchestrator` directory from `orchestrator-helm-chart` to `helm-charts`.
5. Check the changes for each file in the `helm-charts` directory. It's important to keep the CSV's spec section aligned with the field and default values specified in the `values.yaml` file so that the user has a better experience when using the UI when creating a new CR. Most of the time the changes are in the template files. These changes don't require adjustments to the CSV.
	1. Changes to the `values.yaml` or the `values.schema.json` need to be propagated to the file in `config/crd/bases/orchestrator.parodos.dev_orchestrators.yaml` file, such as new fields that need to be added to the csv's `spec.schema.openAPIV3Schema` section with default value as specified in the `values.yaml` file. The `config/samples/orchestrator_v1alpha1_orchestrator.yaml` file is used as the example embedded in the CSV.
	2. Update the spec in the `config/samples/orchestrator_v1alpha1_orchestrator.yaml` file with the contents of the `values.yaml`, unless specified otherwise for that PR (e.g. changes applicable to the `values.yaml` for development purposes but not applicable for the operator as an example).
6. Validate any remaining changes to any other file. It's good to double check for changes introduced that are not required (an empty space, a tab, etc... nothing functional).
7. Commit the changes with message: `Bump helm chart to version X.Y.Z`. The new version of the chart can be found in `helm-charts/orchestrator/Chart.yaml`. Example commit: https://github.com/parodos-dev/orchestrator-helm-operator/commit/9d7c14be0de064a0530d6bfbedcd10cf7b3c1474
8. Update the Makefile to increment the z-stream value by 1 and commit the change to the Makefile as `Release 1.2.0-rc8"`. Example commit: https://github.com/parodos-dev/orchestrator-helm-operator/commit/0bcedf59d03dd0ace380c342ebdb0187d82ad8d6
9. Push the 2 commits.
10. Create a new PR against main, unless the changes are targeting a specific release.
11. Get the PR reviewed by the owner of the changes to the chart or by another team member. Two more pair of eyes are always welcome for these kind of things.
12. Merge the PR.
13. Switch to the main branch and pull the changes so that your fork and upstream are in sync and contain the new additions.
14. Run the following commands in an AMD64 environment.	These commands will build the controller image, push it to the `quay.io/orchestrator/orchestrator-operator` [repository](https://quay.io/repository/orchestrator/orchestrator-operator?tab=tags), build the bundle (update the contents of `/bundle` based on the information in `/config`), build the bundle image and push it to the [repository](https://quay.io/repository/orchestrator/orchestrator-operator-bundle?tab=tags), and finally build the catalog container image and push it to it's [repository](https://quay.io/repository/orchestrator/orchestrator-operator-catalog?tab=tags).

```shell
make docker-build docker-push bundle bundle-build bundle-push catalog-build catalog-push
```


15. Navigate to the [catalog repository](https://quay.io/repository/orchestrator/orchestrator-operator-catalog?tab=tags) and locate the latest build image. The last modified value should give it away but worth checking just in case the push failed (e.g. podman could not authenticate against quay.io because credentials have expired).
16. Retrieve the SHA256 digest (e.g. `sha256:0aff5f6dfdd0eb25ca81f6b6aceee98bff8737b507632733e2d44f1821518e1e` ) and create a new catalog source manifest that points to that new image:
```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: orchestrator-operator
  namespace: openshift-marketplace
spec:
  displayName: Orchestrator Operator
  publisher: Red Hat
  sourceType: grpc
  grpcPodConfig:
    securityContextConfig: restricted
  image: quay.io/orchestrator/orchestrator-operator-catalog@sha256:0aff5f6dfdd0eb25ca81f6b6aceee98bff8737b507632733e2d44f1821518e1e
  updateStrategy:
    registryPoll:
      interval: 10m
```
17. Deploy the catalogsource in your cluster and ensure that the latest version in the OLM menu for the orchestrator operator matches with the new version of the operator.
18. Install the operator and create a sample CR. Validate the CR deploys successfully by checking its status. You can take it further a notch and validate that the related objects also successfully deploy.
19. Share the new manfiest in the development channel to announce the new release. Tag the QE team so that they are aware and can take action as soon as they are able.