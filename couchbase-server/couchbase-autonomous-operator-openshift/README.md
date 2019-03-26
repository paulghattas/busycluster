## Create an OpenShift Project

`oc login -u system:admin`
`oc new-project operator-couchbase-namespace`

## Install the Custom Resource Definition

`oc create -f crd.yaml`

## Create an imagePullSecret for the RH Container Catalog

`oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com --docker-username=pghattas@redhat.com --docker-password=Gatuso.9 --docker-email=pghattas@redhat.com`

oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com \
  --docker-username=<rhel-username> --docker-password=<rhel-password> --docker-email=<docker-email>

## Create a Role and Service Account for the Operator

` oc create -f cluster-role-sa.yaml`

## Create a service account and then assing the cluster role to that service account using a role binding:

`oc create serviceaccount couchbase-operator --namespace operator-couchbase-namespace`

## Register imagePullSecret with the service account that runs the operator

` oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull`

`oc secrets add serviceaccount/default secrets/rh-catalog --for=pull`  

## Assing cluster role to service account

`oc create clusterrolebinding couchbase-operator-rolebinding --clusterrole couchbase-operator --serviceaccount operator-couchbase-namespace:couchbase-operator`

## You can also create a role for a user

`oc create -f cluster-role-user.yaml`

## Allow this user (developer in this case) to manage the couchbase cluster

`oc create rolebinding couchbasecluster-developer-rolebinding --clusterrole couchbasecluster --user developer --namespace operator-couchbase-namespace`

## If you want (Developer) to manage CouchbaseCluster objects in all projects then you can run the following command instead:

`oc create clusterrolebinding couchbasecluster-developer-rolebinding --clusterrole couchbasecluster --user developer`

## Create the Operator

You can now use the developer user to create the operator in operator-couchbase-namespace

`oc logout `
`oc login -u developer `
`oc create -f operator.yaml -n operator-couchbase-namespace`

This command downloads the Operator Docker image and creates a deployment which manages a single instave of the operator.

## Check the status of the Deployment

`oc get deployments -l app=couchbase-operator`

## Check the status of the Operator

`oc get pods -l app=couchbase-operator`

## Check the logs

`oc logs <use name of pod above>`

## Uninstalling the operator

oc delete deployment couchbase-operator
oc delete crd couchbaseclusters.couchbase.com

## To deploy a Couchbase Server cluter using the Operator - all you have to do is create a Couchbase cluster configuration file that describes what you want the cluster to look like and then push the configuration file.

` oc create -f secret.yaml `
` oc create -f couchbase-cluster.yaml`
` oc get pods`
