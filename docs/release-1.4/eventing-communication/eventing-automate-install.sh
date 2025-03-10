#!/bin/bash

set -e
set -x
program_name=$0

KNATIVE_VERSION=1.15.8

function usage {
    echo -e "Usage: ORCHESTRATOR_NAME=ORCHESTRATOR_NAME BROKER_NAME=BROKER_NAME BROKER_NAMESPACE=BROKER_NAMESPACE [KAFKA_REPLICATION_FACTOR=KAFKA_REPLICATION_FACTOR] [ORCHESTRATOR_NAMESPACE=openshift-operators] [BROKER_TYPE=Kafka] [INSTALL_KAFKA_CLUSTER=true] $program_name"
    echo "  ORCHESTRATOR_NAME                   Name of the installed orchestrator CR"
    echo "  ORCHESTRATOR_NAMESPACE              Optional, namespace in which the orchestrator operator is deployed. Default is openshift-operators"
    echo "  BROKER_NAME                         Name of the broker to install"
    echo "  BROKER_NAMESPACE                    Namespace in which the broker must be installed"
    echo "  BROKER_TYPE                         Optional , type of the broker. Either 'Kafka' or 'in-memory'. Default is: 'Kafka'"
    echo "  INSTALL_KAFKA_CLUSTER               Optional, if set to true, indicates that Kafka cluster must be installed. Will only be used if BROKER_TYPE is 'Kafka'. Default is: true"
    echo "  KAFKA_REPLICATION_FACTOR            Optional, only used if INSTALL_KAFKA_CLUSTER is set to false and BROKER_TYPE is 'Kafka', provide the replication factor for the Kafka cluster"
    exit 1
}

OCP_VERSION=$(oc get clusterversion -o jsonpath='{.items[0].status.history[0].version}')
if [[ -z "$OCP_VERSION" ]]; then
    echo "Error: Could not retrieve OpenShift version."
    usage
fi

if [[ "$OCP_VERSION" < "4.15" ]]; then
    echo "Error: OpenShift version $OCP_VERSION must be 4.15 or higher."
    usage
fi

if [[ -z "${ORCHESTRATOR_NAMESPACE}" ]]; then
  ORCHESTRATOR_NAMESPACE=openshift-operators
fi

if [[ -z "${ORCHESTRATOR_NAME}" ]]; then
  echo "ORCHESTRATOR_NAME env variable must be set to the name of the deployed orchestrator CR; e.g: orchestrator-sample"
  usage
fi

if [[ -z "${BROKER_TYPE}" ]]; then
  BROKER_TYPE=Kafka
fi

if [[ "$BROKER_TYPE" != "Kafka" && "$BROKER_TYPE" != "in-memory" ]]; then
  echo 'Error: BROKER_TYPE env variable must be set to either "Kafka" or "in-memory"'
  usage
fi

if [[ -z "${INSTALL_KAFKA_CLUSTER}" ]]; then
  if [ "$BROKER_TYPE" == "Kafka" ]; then
    INSTALL_KAFKA_CLUSTER=true
  else
    INSTALL_KAFKA_CLUSTER=false
  fi
fi

if [[ -z "${BROKER_NAME}" ]]; then
  echo "BROKER_NAME env variable must be set to the name of the broker; e.g: kafka-broker."
  usage
fi

if [[ -z "${BROKER_NAMESPACE}" ]]; then
  echo "BROKER_NAMESPACE env variable must be set to the namespace of the broker; e.g: ${TARGET_NS}."
  usage
fi

if [ "$INSTALL_KAFKA_CLUSTER" == true ]; then
    echo "Installing a kafka cluster using Strimzi default quickstart: https://strimzi.io/quickstarts/"
    oc create namespace kafka
    oc create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
    oc apply -f https://strimzi.io/examples/latest/kafka/kraft/kafka-single-node.yaml -n kafka 
    oc wait kafka/my-cluster --for=condition=Ready --timeout=300s -n kafka 
    KAFKA_REPLICATION_FACTOR=1
fi

if [ "$BROKER_TYPE" == "Kafka" ]; then
    if [[ -z "${KAFKA_REPLICATION_FACTOR}" ]]; then
      echo "KAFKA_REPLICATION_FACTOR env variable must be set when INSTALL_KAFKA_CLUSTER is set to false and BROKER_TYPE is 'Kafka'."
      usage
    fi
    echo "Installing Knative ${KNATIVE_VERSION} Kafka-related resources"

    oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v"${KNATIVE_VERSION}"/eventing-kafka-controller.yaml
    oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v"${KNATIVE_VERSION}"/eventing-kafka-broker.yaml
    oc -n knative-eventing adm policy add-scc-to-user nonroot-v2 -z knative-kafka-broker-data-plane
    oc patch cm kafka-broker-config -n knative-eventing \
    --type merge \
    -p '
    {
        "data": {
        "default.topic.replication.factor": "'"${KAFKA_REPLICATION_FACTOR}"'"
        }
    }'

    oc wait --for condition=ready=true pod -l app=kafka-broker-receiver -n knative-eventing --timeout=60s

    echo "Creating broker..."
    echo "apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  annotations:
      # case-sensitive
      eventing.knative.dev/broker.class: Kafka
  name: ${BROKER_NAME}
  namespace: ${BROKER_NAMESPACE}
spec:
  # Configuration specific to this broker.
  config:
      apiVersion: v1
      kind: ConfigMap
      name: kafka-broker-config
      namespace: knative-eventing" | oc apply -f -
else
    echo "Using in-memory broker"
    echo "apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
    name: ${BROKER_NAME}
    namespace: ${BROKER_NAMESPACE}" | oc apply -f -
fi


echo "Updating SonataflowPlatform to set the eventing spec"
oc -n "${ORCHESTRATOR_NAMESPACE}" patch orchestrators.rhdh.redhat.com "${ORCHESTRATOR_NAME}" --type merge \
   -p '
{
  "spec": {
    "orchestrator": {
      "sonataflowPlatform": {
        "eventing": {
          "broker": {
            "name": "'"${BROKER_NAME}"'",
            "namespace": "'"${BROKER_NAMESPACE}"'"
          }
        }
      }
    }
  }
}'