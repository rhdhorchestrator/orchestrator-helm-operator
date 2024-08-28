#!/usr/bin/env bash

function _wait_for_not_empty() {
	retries=$1
	wait_retry=$2
	command=$3

	for i in `seq 1 $retries`; do
		ret_value=$(bash -c "$command")
		ret=$?
		if [[ $ret -eq 0 && -n $ret_value ]]; then
		 echo $ret_value
		 return $ret
		fi
		echo 2>"> failed with exit code $ret_value, waiting $wait_retry seconds to retry..."
		if [ "$i" -eq "$retries" ]; then
			echo 2>"Error: Wait command exceeded number of retry attempts ("$retries")"
			return 1
		fi
		sleep $wait_retry
	done
}


# Wait for the subscription to create an installPlan and retrieve its name
installPlan=`_wait_for_not_empty 90 2 "oc get subscriptions.operators.coreos.com -n openshift-operators orchestrator-operator -ojsonpath='{.status.installplan.name}'"`
ret=$?
if [[ "$ret" -ne 0 || -z "$installPlan" ]];then
  echo "Failed to retrieve installPlan name: "$installPlan
  exit 1
fi

# Wait for InstallPlan to reach condition Installed=true
oc wait --for=condition=Installed=true ip -n openshift-operators $installPlan
