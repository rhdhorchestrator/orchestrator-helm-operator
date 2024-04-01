# Build the manager binary
FROM quay.io/jordigilh/helm-operator:dev

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}
