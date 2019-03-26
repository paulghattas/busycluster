# Ansible Service Broker Operator

## Create ServiceCatalogAPIServer
`oc create -f ServiceCatalogAPIServer.yaml`

## Create ServiceCatalogControllerManager
`oc create -f ServiceCatalogControllerManager.yaml `

#Create a project.
`oc new-project automation-broker`


# Create a cluster role binding
`oc create -f clusterrolebinding-automation-service-broker.yaml`


## Create Subscription for the AnsibleServiceBroker
`oc create -f subscription-automationbroker.yaml -n automation-broker`

## Create the AnsibleServiceBroker
`oc create -f clusterservicebroker-ansible-service-broker.yaml -n automation-broker`