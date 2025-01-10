FROM registry.access.redhat.com/ubi9:latest as builder
ARG IMG=registry.redhat.io/rhdh-orchestrator-dev-preview-beta/controller-rhel9-operator@sha256:360bb9efdac236599b268002b4b651e7564a9df2a7626655eb177da54b0171f2
WORKDIR /operator
COPY . .
RUN VERSION=$(grep "^VERSION ?="  Makefile | awk -F'= ' '{print $2}') && \
	IMAGE_TAG_BASE=$(grep "^IMAGE_TAG_BASE ?=" Makefile | awk -F'= ' '{print $2}') && \
	sed -i 's|^\s\sversion: .*|  version: '${VERSION}'|; s|name: orchestrator-operator.v.*|name: orchestrator-operator.v'${VERSION}'|g; s|image: '${IMAGE_TAG_BASE}'.*|image: '$IMG'|g' bundle/manifests/orchestrator-operator.clusterserviceversion.yaml

# Build bundle
FROM scratch

USER 1001

# Expose controller's container image with digest so that we can retrieve it with skopeo when creating the FBC catalog
LABEL controller="registry.redhat.io/rhdh-orchestrator-dev-preview-beta/controller-rhel9-operator@sha256:360bb9efdac236599b268002b4b651e7564a9df2a7626655eb177da54b0171f2"

# Required labels
LABEL com.redhat.component="RHDH Orchestrator Helm Operator"
LABEL distribution-scope="public"
LABEL name="rhdh-orchestrator-helm-operator-bundle"
LABEL release="1.3.0"
LABEL version="1.3.0"
LABEL maintainer="Red Hat jgil@redhat.com"
LABEL url="https://github.com/rhdhorchestrator/orchestrator-helm-operator"
LABEL vendor="Red Hat, Inc."
LABEL description="RHDH Orchestrator introduces serverless asynchronous workflows to Backstage, \
				  with a focus on facilitating the transition of applications to the cloud, \
				  onboarding developers, and enabling users to create workflows for backstage \
				  actions or external systems."
LABEL io.k8s.description="RHDH Orchestrator introduces serverless asynchronous workflows to Backstage, \
				  with a focus on facilitating the transition of applications to the cloud, \
				  onboarding developers, and enabling users to create workflows for backstage \
				  actions or external systems."
LABEL summary="RHDH Orchestrator introduces serverless asynchronous workflows to Backstage, \
				  with a focus on facilitating the transition of applications to the cloud, \
				  onboarding developers, and enabling users to create workflows for backstage \
				  actions or external systems."
LABEL io.k8s.display-name="RHDH Orchestrator Helm Operator"
LABEL io.openshift.tags="openshift,operator,rhdh,orchestrator"

# Core bundle labels.
LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=orchestrator-operator
LABEL operators.operatorframework.io.bundle.channels.v1=alpha
LABEL operators.operatorframework.io.metrics.builder=operator-sdk-v1.35.0
LABEL operators.operatorframework.io.metrics.mediatype.v1=metrics+v1
LABEL operators.operatorframework.io.metrics.project_layout=helm.sdk.operatorframework.io/v1


# Labels for operator certification https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/bundle-directory
LABEL com.redhat.delivery.operator.bundle=true

# This sets the earliest version of OCP where our operator build would show up in the official Red Hat operator catalog.
# vX means "X or later": https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/bundle-directory/managing-openshift-versions
#
# See EOL schedule: https://docs.engineering.redhat.com/display/SP/Shipping+Operators+to+EOL+OCP+versions
#
LABEL com.redhat.openshift.versions="v4.13"

# Labels for testing.
LABEL operators.operatorframework.io.test.mediatype.v1=scorecard+v1
LABEL operators.operatorframework.io.test.config.v1=tests/scorecard/

# Copy files to locations specified by labels.
COPY --from=builder /operator/bundle/manifests /manifests/
COPY --from=builder /operator/bundle/metadata /metadata/
COPY --from=builder /operator/bundle/tests/scorecard /tests/scorecard/
COPY --from=builder /operator/LICENSE /license/
