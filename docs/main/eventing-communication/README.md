# Using Knative broker for eventing communication

## Automated installation steps
Usage:
```
Usage: ORCHESTRATOR_NAME=ORCHESTRATOR_NAME BROKER_NAME=BROKER_NAME BROKER_NAMESPACE=BROKER_NAMESPACE [KAFKA_REPLICATION_FACTOR=KAFKA_REPLICATION_FACTOR] [ORCHESTRATOR_NAMESPACE=openshift-operators] [BROKER_TYPE=Kafka] [INSTALL_KAFKA_CLUSTER=true] ./eventing-automate-install.sh
  ORCHESTRATOR_NAME                   Name of the installed orchestrator CR
  ORCHESTRATOR_NAMESPACE              Optional, namespace in which the orchestrator operator is deployed. Default is openshift-operators
  BROKER_NAME                         Name of the broker to install
  BROKER_NAMESPACE                    Namespace in which the broker must be installed
  BROKER_TYPE                         Optional , type of the broker. Either 'Kafka' or 'in-memory'. Default is: 'Kafka'
  INSTALL_KAFKA_CLUSTER               Optional, if set to true, indicates that Kafka cluster must be installed. Will only be used if BROKER_TYPE is 'Kafka'. Default is: true
  KAFKA_REPLICATION_FACTOR            Optional, only used if INSTALL_KAFKA_CLUSTER is set to false and BROKER_TYPE is 'Kafka', provide the replication factor for the Kafka cluster
```
### Using Kafka broker
#### With pre-existing Kafka cluster
```console
ORCHESTRATOR_NAME=orchestrator-sample \
BROKER_NAME=kafka-broker \
BROKER_NAMESPACE=sonataflow-infra \
INSTALL_KAFKA_CLUSTER=false \
KAFKA_REPLICATION_FACTOR=1 ./eventing-automate-install.sh
```
#### Without existing Kafka cluster
```console
ORCHESTRATOR_NAME=orchestrator-sample \
BROKER_NAME=kafka-broker \
BROKER_NAMESPACE=sonataflow-infra \
INSTALL_KAFKA_CLUSTER=true ./eventing-automate-install.sh
```
### Using in-memory-broker
```console
BROKER_TYPE=in-memory \
ORCHESTRATOR_NAME=orchestrator-sample \
BROKER_NAME=simple-broker \
BROKER_NAMESPACE=sonataflow-infra ./eventing-automate-install.sh
```

## Manual installation steps

### Using Kafka broker
A Kafka broker will bring resiliency and reliability to event losses to the sontaflow eventing context.

#### Pre-requisites

1. A Kafka cluster running, see https://strimzi.io/quickstarts/ for a quickstart setup
2. OpenShift version 4.15 and up, as older versions are not supported 

#### Installation steps
1. Configure and enable Kafka broker feature in Knative: https://knative.dev/v1.15-docs/eventing/brokers/broker-types/kafka-broker/
```console
oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.15.8/eventing-kafka-controller.yaml
oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.15.8/eventing-kafka-broker.yaml
```
> [!NOTE]
> At the time this document was written, the compatible `knative` version was `v1.15.8`. Please refer to [the official documentation](https://knative.dev/v1.15-docs/eventing/brokers/broker-types/kafka-broker/) for more up-to-date instructions for the Kafka broker setup. Knative 1.16.x cannot be used due to incompatibillity with k8s and OCP versions. For more information, please advise the release-compatibillity tables [here](https://github.com/knative/community/blob/main/mechanics/RELEASE-SCHEDULE.md#releases-supported-by-community) and [here](https://access.redhat.com/solutions/4870701).
 * Review the `Security Context Constraints` (`scc`) to be granted to the `knative-kafka-broker-data-plane` service account used by the `kafka-broker-receiver`  deployment:
```console
oc get deployments.apps -n knative-eventing kafka-broker-receiver -oyaml | oc adm policy scc-subject-review --filename -
```
  * i.e:
```console
oc -n knative-eventing adm policy add-scc-to-user nonroot-v2 -z knative-kafka-broker-data-plane
```
* Make sure the `replication.factor` of your Kafka cluster matches the one of the `kafka-broker-config` ConfigMap. With the Strimzi quickstart example, this value is set to `1` (see ConfigMap `my-cluster-dual-role-0`):
```console
oc patch cm kafka-broker-config -n knative-eventing \
   --type merge \
   -p '
   {
     "data": {
       "default.topic.replication.factor": "1"
     }
   }'
```
* Similarly, make sure `bootstrap.servers` property from previous `kafka-broker-config` ConfigMap points to the right bootstrap server, it should match the `Service` created for the Kafka cluster:
```console
oc -n kafka get svc
```
* Wait for the `kafka-broker-receiver` resource to be ready:
```console
oc wait --for condition=ready=true pod -l app=kafka-broker-receiver -n knative-eventing --timeout=60s
```

1. Create Kafka broker (Knative `sink`): see https://docs.openshift.com/serverless/1.35/eventing/brokers/kafka-broker.html for more details:
```Console
BROKER_NAME=kafka-broker # change the name to match your needs
BROKER_NAMESPACE=sonataflow-infra # change to your target namespace
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
    name: ${BROKER_NAME}-config
    namespace: knative-eventing" | oc apply -n sonataflow-infra -f -
```

### Using in-memory-broker
You do not need any external resources to install an in-memory broker:
```Console
BROKER_NAME=kafka-broker # change the name to match your needs
BROKER_NAMESPACE=sonataflow-infra # change to your target namespace
echo "apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  name: ${BROKER_NAME}
  namespace: ${BROKER_NAMESPACE} | oc apply -n sonataflow-infra -f -
```

> [!WARNING]
> When using this type of broker you should keep in mind they are neither reliable nor resilient to event losses.
### Common steps
1. Configure the `sonataflowplatforms.sonataflow.org`: given that the `Orchestrator` is named `orchestrator-sample` and was created under the `orchestrator` namespace:
```console
oc -n openshift-operators patch orchestrators.rhdh.redhat.com orchestrator-sample --type merge \
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
```

The `sinkbinding` and `trigger` resources should be automatically created by the OpenShift Serverless Logic operator:
```
$ oc -n sonataflow-infra get sinkbindings.sources.knative.dev 
NAME                                  SINK                                                                                        READY   REASON
sonataflow-platform-jobs-service-sb   http://kafka-broker-ingress.knative-eventing.svc.cluster.local/orchestrator/kafka-broker    True    

$ oc -n sonataflow-infra get trigger
NAME                                                              BROKER         SUBSCRIBER_URI                                                                             READY   REASON
data-index-jobs-2ac1baab-d856-40bc-bcec-c6dd50951419              kafka-broker   http://sonataflow-platform-data-index-service.orchestrator.svc.cluster.local/jobs          True    
data-index-process-definition-634c6f230b6364cdda8272f98c5d58722   kafka-broker   http://sonataflow-platform-data-index-service.orchestrator.svc.cluster.local/definitions   True    
data-index-process-error-2ac1baab-d856-40bc-bcec-c6dd50951419     kafka-broker   http://sonataflow-platform-data-index-service.orchestrator.svc.cluster.local/processes     True    
data-index-process-node-2ac1baab-d856-40bc-bcec-c6dd50951419      kafka-broker   http://sonataflow-platform-data-index-service.orchestrator.svc.cluster.local/processes     True    
data-index-process-sla-2ac1baab-d856-40bc-bcec-c6dd50951419       kafka-broker   http://sonataflow-platform-data-index-service.orchestrator.svc.cluster.local/processes     True    
data-index-process-state-2ac1baab-d856-40bc-bcec-c6dd50951419     kafka-broker   http://sonataflow-platform-data-index-service.orchestrator.svc.cluster.local/processes     True    
data-index-process-variable-6f721bf111e75efc394000bca9884ae22ac   kafka-broker   http://sonataflow-platform-data-index-service.orchestrator.svc.cluster.local/processes     True    
jobs-service-create-job-2ac1baab-d856-40bc-bcec-c6dd50951419      kafka-broker   http://sonataflow-platform-jobs-service.orchestrator.svc.cluster.local/v2/jobs/events      True    
jobs-service-delete-job-2ac1baab-d856-40bc-bcec-c6dd50951419      kafka-broker   http://sonataflow-platform-jobs-service.orchestrator.svc.cluster.local/v2/jobs/events      True    
```

For each workflow deployed:
  * A `sinkbinding` resource will be created: it will inject the `K_SINK` environment variable into the  `deployment` resource. See https://knative.dev/docs/eventing/custom-event-source/sinkbinding/ for more information about`sinkbinding`.
  * A `trigger` resource will be created for each event consumed by the workflow. See https://knative.dev/docs/eventing/triggers/ for more information about `trigger` and their usage.