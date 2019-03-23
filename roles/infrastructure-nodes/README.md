This role requires that a variable `azs` with a list of AZs to create infra nodes be set.

For example:

```sh
ansible-playbook -e api_url=`oc whoami --show-server` -e '{"azs":["us-east-1"]}' play.yaml
```

Use of this role requires the `openshift` python module. On RHEL7 you can install `python-openshift`

To cleanup (probably don't really want to do this in a live cluster)
```sh
oc delete project openshift-logging
oc delete CatalogSourceConfig -n openshift-marketplace installed-community-openshift-operators
oc delete subscription -n openshift-operators elasticsearch-operator
oc delete CatalogSourceConfig -n openshift-marketplace installed-community-openshift-logging
oc delete crd clusterloggings.logging.openshift.io
oc delete crd elasticsearches.logging.openshift.io
```