# WPOK Helm Chart

This chart deploys the **Worker Pool Operator for WPOK** and optionally
installs its supporting dependencies (Prometheus stack, Keda,
RabbitMQ, Redis, MinIO).  The goal is to provide an out‑of‑the‑box
environment for running worker‑pool based workloads on Kubernetes while
remaining close to the original `hyperflow-worker-pool-operator` Helm
chart.  All major components can be enabled or disabled via
`values.yaml`.

## Prerequisites

* Kubernetes 1.25+ (tested with Minikube v1.31.2)
* [Helm 3](https://helm.sh/) installed and configured

## Quickstart

To install the chart into the `scientific` namespace with default
values:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kedacore https://kedacore.github.io/charts
helm repo add bitnami https://charts.bitnami.com/bitnami

cd wpok-chart
helm upgrade --install wpok . \
  --namespace scientific \
  --create-namespace
```

By default only the worker‑pool operator is deployed; all dependencies
are disabled.  To enable RabbitMQ and Keda, pass their flags:

```bash
helm upgrade --install wpok . \
  --namespace scientific \
  --set rabbitmq.enabled=true \
  --set keda.enabled=true
```

## Values

The following table lists the most important configurable values.  See
`values.yaml` for a complete set of options.

| Key | Description | Default |
| --- | ----------- | ------- |
| `kube-prometheus-stack.enabled` | Deploy the Prometheus operator, Alertmanager and Grafana | `false` |
| `keda.enabled` | Deploy Keda for event‑based autoscaling | `false` |
| `rabbitmq.enabled` | Deploy a RabbitMQ instance via the Bitnami chart | `false` |
| `redis.enabled` | Deploy a Redis instance via the Bitnami chart | `false` |
| `minio.enabled` | Deploy an S3‑compatible MinIO instance | `false` |
| `wpokOperator.enabled` | Deploy the worker‑pool operator and its CRD | `true` |
| `wpokOperator.image` | Container image for the operator | `worker-pool-operator:0.2.6` |
| `wpokOperator.secrets.aws` | Credentials for S3/MinIO access | empty |
| `wpokOperator.secrets.rabbitAdmin` | Credentials for the RabbitMQ management API | `user`/`pass` |
| `wpokOperator.pvc.enabled` | Create a PersistentVolumeClaim for worker scratch space | `true` |
| `wpokOperator.resourceQuota.enabled` | Create a ResourceQuota to cap worker pool resources | `true` |
| `crds.create` | Install the WorkerPool CRD | `true` |

## Notes on Template Configuration

* The templates used to generate WorkerPool children (`deployment.yml`,
  `scaledobject.yml`, `prometheus-rule.yml`) are stored in the
  `wpokOperator.templates` section of `values.yaml`.  You can copy
  the defaults and modify them to customize the behaviour of worker pods.

* When enabling dependencies you may need to adjust
  `watchNamespace`, resource requests, and credentials.  The defaults are
  set for a small‑to‑medium development cluster.

* To remain compatible with the upstream hyperflow chart, this chart
  uses the same resource names and labels where possible.  Custom
  changes (e.g. renamed environment variables from `HF_*` to
  `WPOK_*`) are confined to the templates section.

## CRD Management

By default this chart installs or updates the `WorkerPool`
CustomResourceDefinition.  If your cluster already has a compatible
version of the CRD installed (for example via another chart), set
`crds.create=false` to skip CRD installation.

## Uninstalling

To remove the chart and all resources it created:

```bash
helm uninstall wpok --namespace scientific
```

If you set `crds.create=true` during installation, uninstalling the
chart does **not** remove the CRD.  Remove it manually via
`kubectl delete crd workerpools.hyperflow.agh.edu.pl` if desired.