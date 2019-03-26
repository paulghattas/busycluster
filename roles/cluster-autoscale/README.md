This should ideally be the first role applied to a cluster.

If it is applied after the `infrastructure-nodes` role then it will result in
creating autoscalers for the infra machinesets, which may or may not be
desired.