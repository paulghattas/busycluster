## Installing service catalog

This allows users to connect any of their applications deployed in OpenShift Container Platform to a wide variety of service brokers.

You must install the service catalog by completing the following steps if you plan on using any of the services from the OpenShift Ansible Broker or template service broker.

## Procedure
Enable the service catalog API server.

Use the following command to edit the service catalog API server resource.

`oc edit servicecatalogapiservers`

Under spec, set the managementState field to Managed:

```
    spec:
        logLevel: Normal
        managementState: Managed
```

Save the file to apply the changes.

The Operator installs the service catalog API server component. As of OpenShift Container Platform 4, this component is installed into the openshift-service-catalog-apiserver namespace.

# Enable the service catalog controller manager.

`oc edit servicecatalogcontrollermanagers` 

Under spec, set the managementState field to Managed:

```
spec:
  logLevel: Normal
  managementState: Managed

```

Save the file to apply the changes.

The Operator installs the service catalog controller manager component. As of OpenShift Container Platform 4, this component is installed into the openshift-service-catalog-controller-manager namespace.