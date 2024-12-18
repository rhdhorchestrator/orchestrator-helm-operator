# Build the manager binary
FROM quay.io/orchestrator/helm-operator@sha256:2133941e5b0da5b1c616b48a48ae992c8dee6dd40bd03b8bb3a34255b0e0c684
# quay.io/orchestrator/helm-operator:v1.35.0-cve-fixes-18DEC24


LABEL base-image="quay.io/orchestrator/helm-operator:v1.35.0-cve-fixes-18DEC24"
LABEL com.redhat.component="RHDH Orchestrator Helm Operator"
LABEL distribution-scope="public"
LABEL name="rhdh-orchestrator-helm-operator-bundle"
LABEL release="1.3.0"
LABEL version="1.3.0"
LABEL maintainer="Red Hat jgil@redhat.com"
LABEL url="https://github.com/parodos-dev/orchestrator-helm-operator"
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

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}
