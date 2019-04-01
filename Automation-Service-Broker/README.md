# Ansible (Automation Service Broker) Service Broker Operator

## Prerequisite is to install the Service Catalog

The OpenShift Ansible Broker is an implementation of the Open Service Broker (OSB) API that manages applications defined by Ansible playbook bundles (APBs). APBs provide a method for defining and distributing container applications in OpenShift Container Platform, and consist of a bundle of Ansible playbooks built into a container image with an Ansible runtime. APBs leverage Ansible to create a standard mechanism to automate complex deployments.

## Create ServiceCatalogAPIServer (YOU DO NOT NEED THIS IF YOU HAVE ALREADY INSTALLED THE SERVICECATALOG)
`oc create -f ServiceCatalogAPIServer.yaml`

## Create ServiceCatalogControllerManager (YOU DO NOT NEED THIS IF YOU HAVE ALREADY INSTALLED THE SERVICECATALOG)
`oc create -f ServiceCatalogControllerManager.yaml `

# Installing the OpenShift Ansible Broker Operator

## Create a project.
`oc new-project ansible-service-broker`

## Create a cluster-wide role binding
`oc create -f clusterrolebinding-ansible-service-broker.yaml`


## Create Subscription for the AnsibleServiceBroker
`oc create -f subscription-automationbroker.yaml -n ansible-service-broker`

Next, you must start the OpenShift Ansible Broker in order to access the service bundles it provides.

## Create the AnsibleServiceBroker
`oc create -f ansibleservicebroker-ansible-service-broker.yaml -n ansible-service-broker`