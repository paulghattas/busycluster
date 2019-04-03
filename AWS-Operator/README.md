# AWS Operator

This will install the AWS-Service-Operator in your cluster.  Most of the details and examples came from [https://github.com/awslabs/aws-service-operator](https://github.com/awslabs/aws-service-operator)

## First we need kube2iam

```
oc apply -f kube2iam.yaml
```

## Next we need to get our specific ARN so we can create the iam role for the aws-service-operator

```
oc get machineset -n openshift-machine-api
```

The output should look like `clusterName-8xfsn-worker-us-east-2a`

We need to transpose that output to the format `clusterName-8xfsn-worker-role` so we can grab the arn for our worker nodes.

Grab the ARN value.  *note, make sure that you have the awscli installed and configured to run this command*

```
aws iam get-role --role-name clusterName-8xfsn-worker-role | grep arn
```

Create the role while substituing the K8S_WORKER_NODE_IAM_ROLE with your arn value from the previous command

```
aws cloudformation create-stack \
  --stack-name aws-service-operator-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file://aws-service-operator-role.yaml \
  --parameters \
    ParameterKey=WorkerArn,ParameterValue=<K8S_WORKER_NODE_IAM_ROLE>
```

The cloudformation function should create the iam role and policy correctly, assuming the iam role `aws-service-operator` doesn't already exist in your AWS account.  If this role exists already then you should just need to assume a policy to that role.

**YOU DO NOT NEED TO RUN THE COMMAND BELOW IF THE CLOUDFORMATION STACK RAN CORRECTLY AND YOU DID NOT ALREADY HAVE THE IAM ROLE `aws-service-operator`**

Before you assume a new policy you need to edit the `kube2iam.json` file to fill in your K8S_WORKER_NODE_IAM_ROLE

```
aws iam update-assume-role-policy --role-name=aws-service-operator --policy-document=file://kube2iam.json
```


## Apply the aws-service-operator

Modify the `ACCOUNT_ID, REGION, CLUSTER_NAME` in the `aws-service-operator.yaml` with your unique values

Then apply the aws-service-operator

```
oc apply -f aws-service-operator.yaml
```

Next apply the aws cloudformation templates.  *In the case of openshift, these probably should be translated to a template and installed in the `openshift` namespace so that the template service broker can pick them up, but for now we have the CLI methods of interacting with the aws-service-operator only*

```
oc apply -f cloudformationtemplates
```

## Test it by creating an ECR repository

```
oc apply -f examples/ecrrepository.yaml
```

## Validate the ECR repo came up using the AWS console or CLI

In the CLI we can test it via

```
aws ecr describe-repositories
```

And validating `example-repository-name` exists.

## Cleanup/removal

```
oc delete -f examples/ecrrepository.yaml
oc delete -f cloudformationtemplates
oc delete -f aws-service-operator.yaml
oc delete -f kube2iam.yaml
aws cloudformation delete-stack --stack-name=aws-service-operator-role
```

*note, you likely also need to delete the aws iam role that was created for kube2iam*

```
aws iam delete-role --role-name=aws-service-operator
```

*or in the case of you just updating the policy for that existing role*

You need to remove the entire second block in the kube2iam.json file that has your worker node's specific ARN and rerun the update-assume-role-policy
