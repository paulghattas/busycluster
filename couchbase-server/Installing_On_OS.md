Installing Couchbase Autonomous Operator on a Red Hat OpenShift
This guide walks through the recommended procedure for installing the Couchbase Autonomous Operator on a Red Hat OpenShift project.
If you are looking to upgrade an existing installation of the Operator, see Upgrading the Autonomous Operator.This guide assumes the following:
You have a working knowledge of OpenShift and Kubernetes
You are installing on a new OpenShift cluster
You have access to an OpenShift user that has cluster-admin privileges (system:adminin this guide)
You have access to a standard OpenShift user without cluster-admin privileges (developer in this guide)
If you have an OpenShift environment that already has a custom setup (non-default), you should be able to modify a few of the parameters in the various commands and configuration files mentioned in this guide in order to fit your requirements.
This guide makes certain assumptions about the role-based access control (RBAC) settings in your OpenShift environment. Refer to the RBAC documentation before you install the Operator, as your OpenShift environment may differ from the environment upon which this guide is based.
Prerequisites
Download the Operator package and unpack it on the same computer where you normally run oc.
The Operator package contains YAML configuration files and command-line tools that you will use to install the Operator.
After you unpack the download, the resulting directory will be titled something like couchbase-autonomous-operator-openshift.x.x-linux_x86_64. Make sure to cd into this directory before you run the commands in this guide.
Create an OpenShift Project
The first thing that you need to do is use a standard OpenShift user to create a project where the Operator will reside:
oc login -u developer
oc new-project operator-example-namespace
oc logout
In this example, the standard user is developer, and the project is operator-example-namespace. Later in this guide you will give developer the ability to manage the Operator and the Couchbase Server clusters in operator-example-namespace.
Install the Custom Resource Definition
The next step in setting up the Operator is to install the CouchbaseCluster custom resource definition (CRD). The Operator can do this for you automatically (as it does when installing on open source Kubernetes), but in OpenShift it’s better to do it manually because installing a CRD is a cluster-level operation and requires cluster-level permissions that should not be given to typical users.
To install the CRD, log in as an OpenShift user that has cluster-admin privileges (in this case system:admin) and run the following commands:
oc login -u system:admin
oc create -f crd.yaml
You only need to install the CRD once. After that, you can create the Operator in any OpenShift project.
Create an imagePullSecret
Red Hat recommends that all containers that run in OpenShift be built with Red Hat Enterprise Linux. Couchbase provides these images to users through the Red Hat Container Catalog. Using this catalog requires creating an imagePullSecret so that Docker knows where to look for images. To create an imagePullSecret for the Red Hat Container Catalog, run the following command:
oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com \
  --docker-username=<rhel-username> --docker-password=<rhel-password> --docker-email=<docker-email>
Create a Role and Service Account for the Operator
You need to create a role in OpenShift that allows the Operator to access the resources that it needs to run. Since the Operator might run in many different projects, it’s best to create a cluster role because you can assign that role to a service account in any OpenShift project.
To create the cluster role for the Operator, run the following command as the system:admin user:
oc create -f cluster-role-sa.yaml
You only need to create the cluster role once.
After the cluster role is created, you need to create a service account in the project where you are installing the Operator, and then assign the cluster role to that service account using a role binding:
To create the service account:
oc create serviceaccount couchbase-operator --namespace operator-example-namespace
Next we need to register our imagePullSecret with the service account that runs the operator so that it can pull images from the Red Hat Container Catalog.
oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull
oc secrets add serviceaccount/default secrets/rh-catalog --for=pull
To assign the cluster role to the service account:
oc create clusterrolebinding couchbase-operator-rolebinding --clusterrole couchbase-operator --serviceaccount operator-example-namespace:couchbase-operator
A service account is used as opposed to a traditional user for the Operator because service accounts are meant to be used for processes running in OpenShift.
To set up a service account for the Operator in another OpenShift project, repeat these steps again in that project.
Create a Role for a User
Since the developer user needs to be able to create and delete the Couchbase cluster, you need to create another cluster role with permissions to handle the management of the CouchbaseCluster resource.
Run the following command to create the cluster role for developer:
oc create -f cluster-role-user.yaml
Next, you need to allow developer to be able to manage the CouchbaseCluster resource in the operator-example-namespace project:
oc create rolebinding couchbasecluster-developer-rolebinding --clusterrole couchbasecluster --user developer --namespace operator-example-namespace
Alternatively, if you want developer to be able to manage CouchbaseCluster objects in all projects, then you can run the following command instead:
oc create clusterrolebinding couchbasecluster-developer-rolebinding --clusterrole couchbasecluster --user developer
If you want to create role bindings for multiple users either at the cluster or namespace level, they will need to have unique names. In the previous examples, if you were to create a role binding for user alice, you’d use the name couchbasecluster-alice in place of couchbasecluster-developer.
Create the Operator
At this point you can now use the developer user to create the Operator in the operator-example-namespace project. To create and start the Operator, run the following command:
oc logout
oc login -u developer
oc create -f operator.yaml -n operator-example-namespace
Running this command downloads the Operator Docker image (specified in the operator.yaml file) and creates a deployment, which manages a single instance of the Operator. The Operator uses a deployment so that it can restart if the pod it’s running in dies.
After you run the oc create command, it generally takes less than a minute for OpenShift to deploy the Operator and for the Operator to be ready to run.
Check the Status of the Deployment
You can use the following command to check on the status of the deployment:
oc get deployments
If you run the previous command immediately after the Operator is deployed, the output will look something like the following:
NAME                 DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
couchbase-operator   1         1         1            0           10s
In this case, the deployment is called couchbase-operator. The DESIRED field in the output shows that this deployment will create one pod running the Operator. The CURRENT field shows that one Operator pod has been created. However, the AVAILABLE field indicates that the pod is not ready yet since its value is 0 and not 1. That means that the Operator is still establishing a connection to the Kubernetes master node to allow it to get updates on CouchbaseCluster objects. Once the Operator has completed this task, it will be able to start managing Couchbase Server clusters and the status will be shown as AVAILABLE.
You should continue to poll the status of the Operator until the output looks similar to the following:
NAME                 DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
couchbase-operator   1         1         1            1           47s
Check the Status of the Operator
You can use the following command to verify that the Operator has started successfully:
oc get pods -l app=couchbase-operator
If the Operator is up and running, the command returns an output where the READY field shows 1/1, such as:
NAME                                  READY   STATUS   RESTARTS   AGE
couchbase-operator-1917615544-t5mhp   1/1     Running  0          57s
You can also check the logs to confirm that the Operator is up and running. Look for the message: starting couchbaseclusters controller
oc logs couchbase-operator-1917615544-t5mhp
You should see output similar to the following:
time="2018-04-25T03:01:56Z" level=info msg="Obtaining resource lock" module=main
time="2018-04-25T03:01:56Z" level=info msg="Starting event recorder" module=main
time="2018-04-25T03:01:56Z" level=info msg="Attempting to be elected the couchbase-operator leader" module=main
time="2018-04-25T03:02:13Z" level=info msg="I'm the leader, attempt to start the operator" module=main
time="2018-04-25T03:02:13Z" level=info msg="Creating the couchbase-operator controller" module=main
time="2018-04-25T03:02:13Z" level=info msg="Event(v1.ObjectReference{Kind:\"Endpoints\", Namespace:\"default\", Name:\"couchbase-operator\", UID:\"9b86c750-47e7-11e8-866e-080027b2a68d\", APIVersion:\"v1\", ResourceVersion:\"23482\", FieldPath:\"\"}): type: 'Normal' reason: 'LeaderElection' couchbase-operator-75ddfdbdb5-bz7ng became leader" module=event_recorder
time="2018-04-25T03:02:13Z" level=info msg="starting couchbaseclusters controller"
Next Steps
Install the cbopctl command line tool and use it to deploy a Couchbase Server cluster.
Quick Start Script
The script below has been parameterized for clarity and relies on a set of environment variables that may be tailored to the individual OpenShift environment being deployed in. These variables correspond to the resources being created and used in order to deploy the Operator. These are explained below:NAMESPACE
The Kubernetes namespace/OpenShift project to run the Operator in. This can be changed to any project you have access to.ADMIN_ACCOUNT
The administrator account which has the ability to install custom resource definitions and create role bindings which grant privilege escalation.OPERATOR_SERVICE_ACCOUNT
The service account the Operator should run as. This can be changed to any valid Kubernetes name, however, is scoped to the namespace it is deployed in so it must be unique in that context.
This value is also used when creating the Operator deployment, see the documentation for the serviceAccountName parameter.OPERATOR_CLUSTER_ROLE
The role for the Operator to inherit that grants access to create and delete required resources. This name is hard coded in the resource YAML file used in this example.OPERATOR_CLUSTER_ROLE_BINDING
The name for the rule which binds the operator role and service account to a namespace. This can be changed to any unique name in the namespace.USER_ACCOUNT
The user account that is used to create and manage CouchbaseCluster resources. This can be changed to any valid user name.USER_CLUSTER_ROLE
The role for the user to inherit that grants access to create and delete required resources. This name is hard coded in the resource YAML file used in this example.USER_CLUSTER_ROLE_BINDING
The name for the rule which binds the user role and account to a name space. This can be changed to any unique name in the namespace.
All steps listed here are fully explained below. If they fail, please consult the relevant documentation.
# Evnvironment specific variables
ADMIN_ACCOUNT=system:admin
USER_ACCOUNT=developer
NAMESPACE=operator-example-namespace

# Namespace specific variables, you may need to change these to avoid
# name space collisions
OPERATOR_SERVICE_ACCOUNT=couchbase-operator
OPERATOR_CLUSTER_ROLE_BINDING=couchbase-operator-rolebinding
USER_CLUSTER_ROLE_BINDING=couchbasecluster-developer-rolebinding

# Constant variables (defined in web based resources)
OPERATOR_CLUSTER_ROLE=couchbase-operator
USER_CLUSTER_ROLE=couchbasecluster

# As an unprivileged user create a project to run the Operator in and a
# service account to run the Operator as
oc login -u ${USER_ACCOUNT}
oc new-project ${NAMESPACE}
oc create serviceaccount ${OPERATOR_SERVICE_ACCOUNT} --namespace ${NAMESPACE}
oc logout

# As a privileged user create the custom resource definition, roles and bind
# them to the service and user accounts
oc login -u ${ADMIN_ACCOUNT}
oc create -f crd.yaml
oc create -f cluster-role-sa.yaml
oc create -f cluster-role-user.yaml
oc create clusterrolebinding ${OPERATOR_CLUSTER_ROLE_BINDING} --clusterrole ${OPERATOR_CLUSTER_ROLE} --serviceaccount ${NAMESPACE}:${OPERATOR_SERVICE_ACCOUNT}
oc create rolebinding ${USER_CLUSTER_ROLE_BINDING} --clusterrole ${USER_CLUSTER_ROLE} --user ${USER_ACCOUNT} --namespace ${NAMESPACE}
oc logout

# To enable automatic installation of images from the Red Hat Container Catalog,
# you will require a Red Hat account and configure a kubernetes secret with your
# Red Hat username and password. Once you create your secret you must assign it
# to the couchbase-operator and default service accounts.
oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com \
  --docker-username=<rhel-username> --docker-password=<rhel-password> --docker-email=<docker-email>
oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull
oc secrets add serviceaccount/default secrets/rh-catalog --for=pull

# Deploy the Operator as an unprivileged user
oc login -u ${USER_ACCOUNT}
oc create -f operator.yaml -n ${NAMESPACE}
oc logout
Uninstalling the Operator
Uninstalling the Operator is a two-step process:
Delete the Operator.
You can delete the Operator as the developer or system:admin user.
oc delete deployment couchbase-operator

Deleting the Operator from a namespace will not remove or affect any Couchbase pods in your Kubernetes cluster.
Delete the CRD.

You can only delete the CRD as the system:admin user.
Make sure the Operator has been deleted from all other OpenShift projects in the cluster before you delete the CRD. Once the Operator has been deleted, run the following command to delete the CRD:
oc delete crd couchbaseclusters.couchbase.com