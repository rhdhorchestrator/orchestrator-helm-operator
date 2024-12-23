# Using Knative Kafka broker
If you want to use a Knative broker for communication between the different componenets (Data Index, Job Service and Workflows), you should use a reliable broker, i.e: not in-memory.

Kafka perfectly fullfills this reliability need.

## Pre-requisites

1. A Kafka cluster running, see https://strimzi.io/quickstarts/ for a quickstart setup

## Installation steps

1. Configure and enable Kafka broker feature in Knative: https://knative.dev/docs/eventing/brokers/broker-types/kafka-broker/
```console
oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.5/eventing-kafka-controller.yaml
oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.5/eventing-kafka-broker.yaml
```
> [!NOTE]
> At the time this document was written, the latest `knative` version was `v1.14.5`. Please refer to [the latest official documentation](https://knative.dev/docs/eventing/brokers/broker-types/kafka-broker/) for more up-to-date instructions for the Kafka broker setup.
 * Review the `Security Context Constraints` (`scc`) to be granted to the `knative-kafka-broker-data-plane` service account used by the `kafka-broker-receiver`  deployment:
```console
oc get deployments.apps -n knative-eventing kafka-broker-receiver -oyaml | oc adm policy scc-subject-review --filename -
```
  * i.e:
```console
oc -n knative-eventing adm policy add-scc-to-user nonroot-v2 -z knative-kafka-broker-data-plane
```

* Make sure the `replication.factor` of your Kafka cluster match the one of the `kafka-broker-config` ConfigMap. With the Strimzi quickstart example, this value is set to `1`:
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
  * Wait for the `kafka-broker-receiver` resource to be ready:
```console
oc wait --for condition=ready=true pod -l app=kafka-broker-receiver -n knative-eventing --timeout=60s
```

2. Create Kafka broker (Knative `sink`): see https://docs.openshift.com/serverless/1.35/eventing/brokers/kafka-broker.html for more details:
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
3. Configure the `sonataflowplatforms.sonataflow.org`: given that the `Orchestrator` is named `orchestrator-sample` and was created under the `orchestrator` namespace:
```console
oc -n orchestrator patch orchestrators.rhdh.redhat.com orchestrator-sample --type merge \
   -p '
{
  "spec": {
    "orchestrator": {
      "sonataflowPlatform": {
        "eventing": {
          "broker": {
            "name": "${BROKER_NAME}",
            "namespace": "${BROKER_NAMESPACE}"
          }
        }
      }
    }
  }
}'
```

The `sinkbinding` and `trigger` resources should be automatically created by the OSL operator:
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

For each workflows deployed:
  * A `sinkbinding` resource will be created: it will inject the `K_SINK` environment variable into the  `deployment` resource. See https://knative.dev/docs/eventing/custom-event-source/sinkbinding/ for more information about`sinkbinding`.
  * A `trigger` resource will be created for each event consumed by the workflow. See https://knative.dev/docs/eventing/triggers/ for more information about `trigger` and their usage.