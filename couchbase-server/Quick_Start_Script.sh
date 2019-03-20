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