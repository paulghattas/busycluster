https://docs.openshift.com/container-platform/4.0/machine_management/creating-infrastructure-machinesets.html

Creating infrastructure MachineSets
This documentation is for Beta only and might not be complete or fully tested.
OpenShift Container Platform infrastructure components
Machine API overview
Creating infrastructure MachineSets for production environments
Creating a MachineSet
Moving resources to infrastructure MachineSets
Moving the router
Moving the default registry
Moving the monitoring solution
Moving the logging aggregation solution
You can create a MachineSet to host only infrastructure components. You apply specific Kubernetes labels to these Machines and then update the infrastructure components to run on only those Machines.These infrastructure nodes are not counted toward the total number of subscriptions that are required to run the environment.

OpenShift Container Platform infrastructure components
The following OpenShift Container Platform components are infrastructure components:

Kubernetes and OpenShift Container Platform control plane services that run on masters

The default router

The container image registry

The cluster metrics collection, or monitoring service

Cluster aggregated logging

Service brokers

Any node that runs any other container, pod, or component is a worker node that your subscription must cover.

Machine API overview
For OpenShift Container Platform 4 clusters, the Machine API performs all node management actions after the cluster installation finishes. Because of this system, OpenShift Container Platform 4 offers an elastic, dynamic provisioning method on top of public or private cloud infrastructure.

The Machine API is a combination of primary resources that are based on the upstream Cluster API project and custom OpenShift Container Platform resources.

The two primary resources are:

Machines
A fundamental unit that describes a Node. A machine has a providerSpec, which describes the types of compute nodes that are offered for different cloud platforms. For example, a machine type for a worker node on Amazon Web Services (AWS) might define a specific machine type and required metadata.

MachineSets
Groups of machines. MachineSets are to machines as ReplicaSets are to Pods. If you need more machines or need to scale them down, you change the replicas field on the MachineSet to meet your compute need.

The following custom resources add more capabilities to your cluster:

MachineAutoscaler
This resource automatically scales machines in a cloud. You can set the minimum and maximum scaling boundaries for nodes in a specified MachineSet, and the MachineAutoscaler maintains that range of nodes. The MachineAutoscaler object takes effect after a ClusterAutoscaler object exists. Both ClusterAutoscaler and MachineAutoscaler resources are made available by the ClusterAutoscalerOperator.

ClusterAutoscaler
This resource is based on the upstream ClusterAutoscaler project. In the OpenShift Container Platform implementation, it is integrated with the Cluster API by extending the MachineSet API. You can set cluster-wide scaling limits for resources such as cores, nodes, memory, GPU, and so on. You can set the priority so that the cluster prioritizes pods so that new nodes are not brought online for less important pods. You can also set the ScalingPolicy so you can scale up nodes but not scale them down.

MachineHealthCheck
This resource detects when a machine is unhealthy, deletes it, and, on supported platforms, makes a new machine.

In OpenShift Container Platform version 3.11, you could not roll out a multi-zone architecture easily because the cluster did not manage machine provisioning. It is easier in 4.0. Each MachineSet is scoped to a single zone, so the installation program sends out MachineSets across availability zones on your behalf. And then because your compute is dynamic, and in the face of a zone failure, you always have a zone for when you need to rebalance your machines. The autoscaler provides best-effort balancing over the life of a cluster.

Creating infrastructure MachineSets for production environments
In a production deployment, deploy at least three MachineSets to hold infrastructure components. Both the logging aggregation solution and the service mesh deploy ElasticSearch, and ElasticSearch requires three instances that are installed on different nodes. For high availability, install deploy these nodes to different availability zones. Since you need different MachineSets for each availability zone, create at least three MachineSets.

Creating a MachineSet
You can create more MachineSets. Because the MachineSet definition contains details that are specific to the AWS region that the cluster is deployed in, you copy an existing MachineSet from your cluster and modify it.

Prerequisites
Deploy an OpenShift Container Platform cluster.

Install the oc command line and log in as a user with <some permissions>.

Procedure
View the current MachineSets.

$ oc get machinesets -n openshift-machine-api

NAME                         DESIRED   CURRENT   READY     AVAILABLE   AGE
190125-3-worker-us-west-1b   2         2         2         2           3h
190125-3-worker-us-west-1c   1         1         1         1           3
Export the source of a MachineSet to a text file:

$ oc get machineset <machineset_name> -n \
     openshift-machine-api -o yaml > <file_name>.yaml
In this command, <machineset_name> is the name of the current MachineSet that is in the AWS region you want to place your new MachineSet in, such as 190125-3-worker-us-west-1c, and <file_name> is the name of your new MachineSet definition.

Update the metadata section of <file_name>.yaml:

metadata:
  creationTimestamp: 2019-02-15T16:32:56Z 
  generation: 1 
  labels:
    sigs.k8s.io/cluster-api-cluster: <cluster_name> 
    sigs.k8s.io/cluster-api-machine-role: <machine_label> 
    sigs.k8s.io/cluster-api-machine-type: <machine_label> 
  name: <cluster_name>-<machine_label>-<AWS-availability-zone>   
  namespace: openshift-machine-api
  resourceVersion: "9249" 
  selfLink: /apis/cluster.k8s.io/v1alpha1/namespaces/openshift-machine-api/machinesets/<cluster_name>-<machine_label>-<AWS-availability-zone> 
  uid: 59ba0425-313f-11e9-861e-0a18047f0a28 
Remove this line.
Do not change the <cluster_name>.
For each <machine_label> instance, specify the name of the new MachineSet.
Ensure that the AWS availability zone is correct in each instance of the <AWS-availability-zone> parameter.
The metadata section resembles the following YAML:

metadata:
  labels:
    sigs.k8s.io/cluster-api-cluster: <cluster_name>
    sigs.k8s.io/cluster-api-machine-role: <new_machine_label>
    sigs.k8s.io/cluster-api-machine-type: <new_machine_label>
  name: <cluster_name>-<new_machine_label>-<AWS-availability-zone>
  namespace: openshift-machine-api
In <file_name>.yaml, delete the status stanza:

status:
  availableReplicas: 1
  fullyLabeledReplicas: 1
  observedGeneration: 1
  readyReplicas: 1
  replicas: 1
In <file_name>.yaml, update both instances of the sigs.k8s.io/cluster-api-machineset parameter values in the spec section to match the name that you defined in the metadata section:

spec:
  replicas: 1
  selector:
    matchLabels:
      sigs.k8s.io/cluster-api-cluster: cluster_name
      sigs.k8s.io/cluster-api-machineset: <cluster_name>-<machine_label>-<AWS-availability-zone> 
  template:
    metadata:
      creationTimestamp: null
      labels:
        sigs.k8s.io/cluster-api-cluster: <cluster_name>
        sigs.k8s.io/cluster-api-machine-role: <machine_label>
        sigs.k8s.io/cluster-api-machine-type: <machine_label>
        sigs.k8s.io/cluster-api-machineset: <cluster_name>-<machine_label>-<AWS-availability-zone> 
...
Ensure that both the sigs.k8s.io/cluster-api-machineset parameter values match the name that you defined in the metadata section.
In <file_name>.yaml, add the node label definition to the spec. The label definition resembles the following stanza:

  spec:
    metadata:
      labels:
        node-role.kubernetes.io/<label_name>: "" 
In this definition, <label_name> is the node label to add. For example, to add the infra label to the nodes, specify node-role.kubernetes.io/infra.
The updated spec section resembles this example:

spec:
  replicas: 1
  selector:
    matchLabels:
      sigs.k8s.io/cluster-api-cluster: cluster_name
      sigs.k8s.io/cluster-api-machineset: <cluster_name>-<machine_label>-<AWS-availability-zone>
  template:
    metadata:
      creationTimestamp: null
      labels:
        sigs.k8s.io/cluster-api-cluster: <cluster_name>
        sigs.k8s.io/cluster-api-machine-role: <machine_label>
        sigs.k8s.io/cluster-api-machine-type: <machine_label>
        sigs.k8s.io/cluster-api-machineset: <cluster_name>-<machine_label>-<AWS-availability-zone>
    spec: 
      metadata:
        labels:
          node-role.kubernetes.io/<label_name>: ""
...
Place the spec stanza here.
Optionally, modify the EC2 instance type and modify the storage volumes.

Take care to modify only the parameters that describe the EC2 instance type and storage volumes. You must not change the other parameters value in the providerSpec section.

providerSpec:
  value:
    ami:
      id: ami-0e2bcd33dfff9c73e 
    apiVersion: awsproviderconfig.k8s.io/v1alpha1
    blockDevices: 
    - ebs:
        iops: 0
        volumeSize: 120
        volumeType: gp2
    deviceIndex: 0
    iamInstanceProfile: 
      id: <cluster_name>-<machine_label>-profile
    instanceType: m4.large 
    kind: AWSMachineProviderConfig
    metadata:
      creationTimestamp: null
    placement: 
      availabilityZone: <AWS-availability-zone>
      region: <AWS-region>
    publicIp: null
    securityGroups:
    - filters:
      - name: tag:Name
        values:
        - testcluster2_worker_sg
    subnet: 
      filters:
      - name: tag:Name
        values:
        - <cluster_name>-<machine_label>-<AWS-availability-zone>
    tags:
    - name: openshiftClusterID
      value: 5a21bfc0-1c56-4400-81bb-7fd66644f871
    - name: kubernetes.io/cluster/<cluster_name>
      value: owned
    userDataSecret: 
      name: <machine_label>-user-data
You can specify a different valid AMI.
You can customize the volume characteristics for the MachineSet. See the AWS documentation.
Do not modify this section.
Specify a valid instanceType for the AMI that you specified.
Create the new MachineSet:

$ oc create -f <file_name>.yaml
View the list of MachineSets:

$ oc get machineset -n openshift-machine-api


NAME                         DESIRED   CURRENT   READY     AVAILABLE   AGE
190125-3-worker-us-west-1b   2         2         2         2           4h
190125-3-worker-us-west-1c   1         1         1         1           4h
infrastructure-us-west-1b    1         1                               4s
When the new MachineSet is available, the DESIRED and CURRENT values match. If the MachineSet is not available, wait a few minutes and run the command again.

After the new MachineSet is available, check the machine status:

$ oc get machine -n openshift-machine-api
View the new node:

$ oc get node
The new node is the one with the lowest AGE. ip-10-0-128-138.us-west-1.compute.internal

Confirm that the new node has the label that you specified:

$ oc get node <node_name> --show-labels
Review the command output and confirm that node-role.kubernetes.io/<your_label> is in the LABELS list.

Next steps
If you need MachineSets in other availability zones, repeat this process to create more MachineSets.

Moving resources to infrastructure MachineSets
Some of the infrastructure resources are deployed in your cluster by default. You can move them to the infrastructure MachineSets that you created.

Moving the router
You can deploy the router Pod to a different MachineSet. By default, the Pod is displayed to a worker node.

Prerequisites
Configure additional MachineSets in your OpenShift Container Platform cluster.

Procedure
View the clusteringress Custom Resource for the router Operator:

$ oc get clusteringress default -n openshift-ingress-operator -o yaml 
The router is managed by an Operator that is named openshift-ingress-operator, and its Pod is in the openshift-ingress-operator project.
The command output resembles the following text:

apiVersion: ingress.openshift.io/v1alpha1
kind: ClusterIngress
metadata:
  creationTimestamp: 2019-01-28T17:23:39Z
  finalizers:
  - ingress.openshift.io/default-cluster-ingress
  generation: 2
  name: default
  namespace: openshift-ingress-operator
  resourceVersion: "1294295"
  selfLink: /apis/ingress.openshift.io/v1alpha1/namespaces/openshift-ingress-operator/clusteringresses/default
  uid: 73ff7bfd-2321-11e9-8ff2-026a37856868
spec:
  defaultCertificateSecret: null
  highAvailability:
    type: Cloud
  ingressDomain: apps.beta-190128-2.ocp4testing.openshiftdemos.com
  namespaceSelector: null
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/worker: "" 
  replicas: 1
  routeSelector: null
  unsupportedExtensions: null
status:
  labelSelector: app=router,router=router-default
  replicas: 1
Note that the nodeSelector is configured to match the worker label.
Edit the clusteringress resource and change the nodeSelector to use the infra label:

$ oc edit clusteringress default -n openshift-ingress-operator -o yaml
Update the nodeSelector stanza to reference the infra label as shown:

  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/infra: ""
...
Confirm that the router pod is running on the infra node.

View the list of router pods and note the node name of the running pod:

$ oc get pod -n openshift-ingress

NAME                              READY     STATUS        RESTARTS   AGE       IP           NODE                           NOMINATED NODE
router-default-86798b4b5d-bdlvd   1/1       Running       0          28s       10.130.2.4   ip-10-0-217-226.ec2.internal   <none>
router-default-955d875f4-255g8    0/1       Terminating   0          19h       10.129.2.4   ip-10-0-148-172.ec2.internal   <none>
In this example, the running pod is on the ip-10-0-217-226.ec2.internal node.

View the node status of the running pod:

$ oc get node <node_name> 

NAME                           STATUS    ROLES          AGE       VERSION
ip-10-0-217-226.ec2.internal   Ready     infra,worker   17h       v1.11.0+406fc897d8
Specify the <node_name> that you obtained from the pod list.
Because the role list includes infra, the pod is running on the correct node.

Moving the default registry
You configure the registry Operator to deploy its pods to different nodes.

Prerequisites
Configure additional MachineSets in your OpenShift Container Platform cluster.

Procedure
View the config/instance object:

$ oc get config/instance -o yaml
The output resembles the following text:

apiVersion: imageregistry.operator.openshift.io/v1
kind: Config
metadata:
  creationTimestamp: 2019-02-05T13:52:05Z
  finalizers:
  - imageregistry.operator.openshift.io/finalizer
  generation: 1
  name: instance
  resourceVersion: "56174"
  selfLink: /apis/imageregistry.operator.openshift.io/v1/configs/instance
  uid: 36fd3724-294d-11e9-a524-12ffeee2931b
spec:
  httpSecret: d9a012ccd117b1e6616ceccb2c3bb66a5fed1b5e481623
  logging: 2
  managementState: Managed
  proxy: {}
  replicas: 1
  requests:
    read: {}
    write: {}
  storage:
    s3:
      bucket: image-registry-us-east-1-c92e88cad85b48ec8b312344dff03c82-392c
      region: us-east-1
status:
...
Edit the config/instance object:

$ oc edit config/instance
Add the following lines of text the spec section of the object:

  nodeSelector:
    node-role.kubernetes.io/infra: ""
After you save and exit you can see the registry pod being moving to the infrastructure node.

Moving the monitoring solution
The monitoring solution uses Cluster Version Operator (CVO) to create the ConfigMap that the monitoring Operator uses to determine how to deploy its resources. Because it uses the CVO and users cannot modify the CVO, you cannot change where the Operator deploys resources.

Moving the logging aggregation solution
The log aggregation solution in OpenShift Container Platform is not installed by default and cannot currently be deployed.