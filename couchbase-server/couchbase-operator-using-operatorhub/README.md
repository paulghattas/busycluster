# Create an OpenShift Project

`oc login -u system:admin`
`oc new-project couchbase-operator`

## Installing the Couchbase Operator

Subscribe to couchbase-operator

`oc create -f couchbase-operator-subscription.yaml`

## Deploying the Couchbase Cluster

Before creating the Couchbase cluster, create a secret (modify yaml file to create your own secret). The Couchbase Operator reads this upon startup and configures the database with these details.)

`oc create -f couchbase-operator-creds.yaml`


Next, you will create the couchbase-operator in the couchbase-operator namespace. You will need to modify the yaml file below.

For the purposes of this example, you must pay attention to the following parameters:
• namespace
Make sure this matches the name of the project. • authSecret
This is the secret we created. You don’t need to modify this if you’re using the same secret that is in the example. 

`oc create -f couchbasecluster.yaml -n couchbase-operator`



