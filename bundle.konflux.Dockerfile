FROM registry.access.redhat.com/ubi9:latest as builder

WORKDIR /operator
COPY . .
RUN
RUN dnf install make -y && make bundle


FROM scratch

# Core bundle labels.
LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=orchestrator-operator
LABEL operators.operatorframework.io.bundle.channels.v1=alpha
LABEL operators.operatorframework.io.metrics.builder=operator-sdk-v1.33.0
LABEL operators.operatorframework.io.metrics.mediatype.v1=metrics+v1
LABEL operators.operatorframework.io.metrics.project_layout=helm.sdk.operatorframework.io/v1

# Labels for operator certification https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/bundle-directory
LABEL com.redhat.delivery.operator.bundle=true

# This sets the earliest version of OCP where our operator build would show up in the official Red Hat operator catalog.
# vX means "X or later": https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/bundle-directory/managing-openshift-versions
#
# See EOL schedule: https://docs.engineering.redhat.com/display/SP/Shipping+Operators+to+EOL+OCP+versions
#
LABEL com.redhat.openshift.versions="v4.14"

# Labels for testing.
LABEL operators.operatorframework.io.test.mediatype.v1=scorecard+v1
LABEL operators.operatorframework.io.test.config.v1=tests/scorecard/

# Copy files to locations specified by labels.
COPY --from=builder /operator/bundle/manifests /manifests/
COPY --from=builder /operator/bundle/metadata /metadata/
COPY --from=builder /operator/bundle/tests/scorecard /tests/scorecard/
