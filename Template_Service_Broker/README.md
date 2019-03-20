# Template Service Broker Operator

## Create ServiceCatalogAPIServer
`oc create -f ServiceCatalogAPIServer.yaml`

## Create ServiceCatalogControllerManager
`oc create -f ServiceCatalogControllerManager.yaml `

## Create Subscription for the TemplateServiceBroker
`oc create -f subcription-templateservicebroker.yaml -n openshift`

## Create the TemplateServiceBroker
`oc create -f templateservicebroker-template-service-broker.yaml -n openshift`