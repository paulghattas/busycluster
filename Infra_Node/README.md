# OpenShift Infrastructure Nodes

## Get the machine set

```
oc get machineset -n openshift-machine-api
oc get machineset <pick one worker> -o yaml > worker-original.yaml

```
## Sanitize the outputs!
add some fancy sed command or automation to do these things:
- Change the name of the machineSet where needed from worker to infra
- delete the metadata and unique identifers from the original worker machineset
- add the following under `spec.template.spec.metadata`
- save the new file as worker.yaml

```
        labels:
          node-role.kubernetes.io/infra: ""
          infra: "infra"
```

## Apply the MachineSet
`oc create -f worker.yaml`

## Move the router!
`oc patch clusteringress default -n openshift-ingress-operator --type=merge --patch='{"spec":{"nodePlacement":{"nodeSelector": {"matchLabels":{"node-role.kubernetes.io/infra":""}}}}}'`

## Work around to update the router!
`oc delete deployment router-default -n openshift-ingress`

## Scale router deployment to One as we are only deploying one infra node
`oc patch clusteringress default -n openshift-ingress-operator --type=merge --patch='{"spec":{"replicas": 1}}'`
