Deploying a Couchbase Cluster Using the Operator
Prerequisites
Before you attempt to deploy a Couchbase Server cluster with the Couchbase Autonomous Operator, ensure that you have done the following:
You have reviewed the prerequisites
You have deployed the Operator and it is up and running
You have downloaded the Operator package and installed cbopctl
cbopctl is a command line tool similar to kubectl or oc, except that it performs an extra check on the CouchbaseCluster configuration being sent to Kubernetes to ensure that it is valid.
The Operator package also contains YAML configuration files that will help you set up a Couchbase cluster.
After you unpack the download, the resulting directory will be titled something like couchbase-autonomous-operator-kubernetes.x.x-linux_x86_64. Make sure to cd into this directory before you run the commands in this guide.
Preparing the Couchbase Cluster Configuration
To deploy a Couchbase Server cluster using the Operator, all you have to do is create a CouchbaseCluster configuration file that describes what you want the cluster to look like (e.g. number of nodes, types of services, system resources, etc), and then push that configuration file into Kubernetes. Like all Kubernetes configurations, a CouchbaseCluster is defined using either YAML or JSON (YAML is preferred by Kubernetes).
The Operator package contains an example CouchbaseCluster configuration file (couchbase-cluster.yaml), also listed here:Example CouchbaseCluster Configuration for open source Kubernetes (couchbase-cluster.yaml)
apiVersion: couchbase.com/v1
kind: CouchbaseCluster
metadata:
  name: cb-example
spec:
  baseImage: couchbase/server
  version: enterprise-5.5.2
  authSecret: cb-example-auth
  exposeAdminConsole: true
  adminConsoleServices:
    - data
  cluster:
    dataServiceMemoryQuota: 256
    indexServiceMemoryQuota: 256
    searchServiceMemoryQuota: 256
    eventingServiceMemoryQuota: 256
    analyticsServiceMemoryQuota: 1024
    indexStorageSetting: memory_optimized
    autoFailoverTimeout: 120
    autoFailoverMaxCount: 3
    autoFailoverOnDataDiskIssues: true
    autoFailoverOnDataDiskIssuesTimePeriod: 120
    autoFailoverServerGroup: false
  buckets:
    - name: default
      type: couchbase
      memoryQuota: 128
      replicas: 1
      ioPriority: high
      evictionPolicy: fullEviction
      conflictResolution: seqno
      enableFlush: true
      enableIndexReplica: false
  servers:
    - size: 3
      name: all_services
      services:
        - data
        - index
        - query
        - search
        - eventing
        - analytics
By taking a quick look at this configuration file, you can see that it defines a cluster by specifying the following:
Cluster name: cb-example (metadata.name)
Couchbase version: enterprise-5.5.2 (spec.version)
Buckets: 1 bucket named default (spec.buckets)
Size: 3 node cluster with all services on each node (spec.servers)
Secret: cb-example-auth (authSecret)
You can use this example CouchbaseCluster configuration file "as-is" to test out how the Operator deploys a Couchbase Server cluster. However, to deploy a Couchbase cluster that is more specifically tailored to your development and production needs, you need to create your own custom configuration file that conforms to the CouchbaseCluster specification.
Ensure that your Kubernetes environment has the appropriate resources for the Couchbase cluster that you’re trying to deploy.
In the case of Minikube and Minishift, the default memory allocation is 2 GB. This is not sufficient for running a three-node Couchbase cluster like the one in the example configuration. If you’re using the example configuration for demo purposes, you should set the memory allocation to 4 GB at a minimum (8 GB recommended). You should also increase the CPU allocation if you experience poor performance.
You can set the recommended memory and CPU allocation when you start Minikube or Minishift:
About the authSecret Field
One thing that’s important to note is the authSecret field. The Operator uses Kubernetes Secrets to create and manage the Couchbase super-user credentials. As a result, the authSecret field must refer to a secret that contains both a user name and a password field.
For convenience, a sample secret is provided in the Operator package. When you push it to your Kubernetes cluster, the secret sets the user name to Administrator and the password to password.
To push the secret into your Kubernetes cluster, run the following command:
Kubernetes
OpenShift
oc create -f secret.yaml
Deploying the Couchbase Cluster
The next step after creating the CouchbaseCluster configuration file is to push it to Kubernetes. To push the configuration, run the following command:
Kubernetes
OpenShift
cbopctl create -f couchbase-cluster.yaml
After receiving the configuration, the Operator automatically begins creating the cluster. The amount of time it takes to create the cluster depends on the configuration. You can track the progress of cluster creation using the kubectl describe command.
Verifying the Deployment
Once the cluster has been provisioned, you’ll see that various pods, a service, and a Couchbase cluster have been created. If you used the example configuration (which calls for a three-node cluster) you should see three pods created. The Operator also creates an internal headless service that can be used by applications deployed inside the same Kubernetes namespace to connect to the Couchbase cluster.
Run the following command to see the newly created pods:
Kubernetes
OpenShift
oc get pods
The output should look like:
NAME                                  READY     STATUS    RESTARTS   AGE
cb-example-0000                       1/1       Running   0          1m
cb-example-0001                       1/1       Running   0          1m
cb-example-0002                       1/1       Running   0          1m
couchbase-operator-1917615544-pd4q6   1/1       Running   0          8m
A CouchbaseCluster object is also created for the cluster and can be used to get health and status information about the cluster.
