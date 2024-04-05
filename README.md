# orchestrator-helm-operator
Meta Operator for deploying the Orchestrator helm charts


## Upgrading the operator
Updating the operator requires a few manual steps due to the need of the operator's RBAC roles to be in sync with the kind of resources in the chart, so that the operator is able to manage them. Unfortunately it is not possible to leverage on the operator-sdk ability to populate the roles based on the resources generated from the chart as the generation fails because the chart contains certain constrains that prevents it from succeeding without running against an live cluster, such as the need to determine the cluster's domain name from the `ingresses.config.openshift.io` object.

Past this check, the process becomes automated by running a set of targets provided in the `Makefile` that generate the container images consumable by the OLM:

1. Increase the operator's semantic version by updating the VERSION field in the `Makefile`.
2. Delete the contents of the old chart in `helm-charts/orchestrator` to ensure only the new chart manifests are used.
3. Copy the new chart manifests over `helm-charts/orchestrator`.
4. Ensure that the resources in the charts are aligned with the RBAC granted to the operator in the `config/rbac/role.yaml` file. This step can be expedited by determining the differences between the existing and new version of the chart, which resources have been added and which ones have been removed and, most importantly, what is the access required (CRUD).
5. Generate the new container images and push them `make docker-build docker-push`.
6. Test the deployment of the new version of the operator in a new cluster. Use the `make run` to run the operator locally while connected to a live cluster using your current credentials, or deploy as a pod with the command `IMAGE_TAG_BASE=<location of the container image in registry> make docker-build docker-push deploy`. Remember that changes to the `config/rbac/role.yaml` file are only reflected when the operator is deployed as a pod.
7. Once the new version has been validated, run the `make docker-build docker-push` command using the default `IMAGE_TAG_BASE` so that it is published to the registry.
8. Run the following command `make bundle bundle-build bundle-push catalog-build catalog-push`. This command will update the operator's manifest and generate the container images required by OLM.
9. Create a new PR and merge the changes to the repository.
10. Tag the new version in GitHub after the PR is merged.