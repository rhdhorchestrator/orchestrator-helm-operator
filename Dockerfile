# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.35.0 as helm-operator

FROM registry.access.redhat.com/ubi8/ubi

COPY --from=helm-operator /usr/local/bin/helm-operator /usr/local/bin/helm-operator

ENV HOME=/opt/helm \
    USER_NAME=helm \
    USER_UID=1001

RUN /bin/sh -c echo "${USER_NAME}:x:${USER_UID}:0:${USER_NAME} user:${HOME}:/sbin/nologin" >> /etc/passwd

COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts

WORKDIR ${HOME}
USER ${USER_UID}
ENTRYPOINT ["/usr/local/bin/helm-operator", "run", "--watches-file=./watches.yaml"]
