# Using Knative kafka broker
If you want to use a Knative broker for communication between the different componenets (Data Index, Job Service and Workflows), you should use a reliable broker, i.e: not in-memory.

Kafka perfectly fullfil this reliability need.

## Pre-requisites

1. A Kafka cluster running, see https://strimzi.io/quickstarts/ for a quickstart setup

## Installation steps

1. Configure and enable kafka broker feature in Knative: https://knative.dev/docs/eventing/brokers/broker-types/kafka-broker/
  * i.e: 
```console
oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.5/eventing-kafka-controller.yaml
oc apply --filename https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.5/eventing-kafka-broker.yaml
```
    * Note the we are using the version `knative-v1.14.5` in this example, this may change, please refer to the offical documention link provided
  * wait for the `kafka-broker-receiver` resource to be ready:
```console
oc wait --for condition=ready=true pod -l app=kafka-broker-receiver -n knative-eventing --timeout=60s
```
  * Review the `scc` to be granted to the `knative-kafka-broker-data-plane` service account used by the `kafka-broker-receiver`  deployment:
```console
oc get deployments.apps -n knative-eventing kafka-broker-receiver -oyaml | oc adm policy scc-subject-review --filename -
```
    * i.e:
```console
oc -n knative-eventing adm policy add-scc-to-user nonroot-v2 -z knative-kafka-broker-data-plane
```
Make sure the `replication.factor` of your Kafka cluster match the one of the `kafka-broker-config` ConfigMap. With the Strimzi quickstart, this value is `1`:
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
2. Create kafka broker (Knative `sink`): see https://docs.openshift.com/serverless/1.33/eventing/brokers/kafka-broker.html for more details:
```Console
echo "apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  annotations:
    # case-sensitive
    eventing.knative.dev/broker.class: Kafka
  name: kafka-broker
spec:
  # Configuration specific to this broker.
  config:
    apiVersion: v1
    kind: ConfigMap
    name: kafka-broker-config
    namespace: knative-eventing" | oc apply -f -
```
3. Configure the `sonataflowplatforms.sonataflow.org`: given that the resource is created under the `sonataflow-infra` namespace:
```console
oc -n sonataflow-infra patch sonataflowplatforms.sonataflow.org sonataflow-platform --type merge \
   -p '
{
  "spec": {
    "eventing": {
      "broker": {
        "ref": {
          "apiVersion": "eventing.knative.dev/v1",
          "kind": "Broker",
          "name": "<BROKER NAME>",
          "namespace": "<BROKER NAMESPACE>"
        }
      }
    }
  }
}
```

You should have `sinkbinding` and `trigger` created:
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
  * a `sinkbinding` resource will be created: it will inject the `K_SINK` environment variable into the  `deployment` resource. See https://knative.dev/docs/eventing/custom-event-source/sinkbinding/ for more information about`sinkbinding`.
  * a `trigger` resource will be created for each event consumed by the workflow. See https://knative.dev/docs/eventing/triggers/ for more information about `trigger` and their usage.