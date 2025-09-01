# WPOK Helm Chart

This chart deploys the **Worker Pool On Kubernetes (WPOK)** platform and its **core dependencies** to run worker‑pool–based workloads on Kubernetes. It stays close to the upstream `hyperflow-worker-pool-operator`.

**What’s enabled by default**

* **kube-prometheus-stack** (Prometheus Operator + Alertmanager + Grafana)
* **Keda** (event‑based autoscaling)
* **RabbitMQ** (Bitnami)
* **Redis** (Bitnami)
* **ResourceQuota** for the namespace (recommended to tune for your cluster)

**Optional (disabled by default)**

* **MinIO** (S3‑compatible storage) – enable when you want built‑in object storage.

All components can be toggled via `values.yaml` or `--set` flags.

---

## Prerequisites

* Kubernetes **1.25+** (tested with Minikube v1.31.2)
* **Helm 3** installed and configured

---

## Quickstart

Add chart repositories used by dependencies:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kedacore https://kedacore.github.io/charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Install into the desired namespace with the **default stack enabled** (Prometheus/Keda/RabbitMQ/Redis, **MinIO disabled**):

```bash
cd wpok-chart
helm upgrade --install wpok . \
  --namespace wpok \
  --create-namespace
```

> The chart also creates a ResourceQuota by default. This directly drives worker scaling. The target replica count comes from a Prometheus rule that blends each queue’s current load with the namespace’s CPU/memory budget divided by per‑worker requirements

### Enable MinIO (optional)

```bash
helm upgrade --install wpok . \
  -n wpok \
  --set minio.enabled=true
```

### Tune the ResourceQuota (recommended)

By default, the quota is conservative and meant for small dev clusters. Override as needed:

```bash
helm upgrade --install wpok . \
  -n wpok \
  --set wpokOperator.resourceQuota.enabled=true \
  --set wpokOperator.resourceQuota.cpuRequests=16 \
  --set wpokOperator.resourceQuota.memoryRequests=32Gi \
  --set wpokOperator.resourceQuota.cpuLimits=32 \
  --set wpokOperator.resourceQuota.memoryLimits=64Gi
```

If you prefer a file, put overrides into `my-values.yaml` and pass `-f my-values.yaml`.

---

## Applying changes (values/templates)

The operator **mounts its templates from a ConfigMap** and reads configuration via environment variables. To apply updates from `values.yaml` (including template changes):

```bash
helm upgrade wpok . -n wpok -f values.yaml
```

To verify what Helm installed:

```bash
helm get values   wpok -n wpok --all
helm get manifest wpok -n wpok | less
```

---

## Values (high‑impact)

| Key                                         | Description                                                 | Default                      |
| ------------------------------------------- | ----------------------------------------------------------- | ---------------------------- |
| `kube-prometheus-stack.enabled`             | Prometheus Operator stack (Prometheus/Alertmanager/Grafana) | `true`                       |
| `keda.enabled`                              | Event‑based autoscaling                                     | `true`                       |
| `rabbitmq.enabled`                          | Bitnami RabbitMQ                                            | `true`                       |
| `redis.enabled`                             | Bitnami Redis (standalone, no auth by default)              | `true`                       |
| `minio.enabled`                             | MinIO (S3‑compatible object storage)                        | `false`                      |
| `wpokOperator.enabled`                      | Deploy the Worker‑Pool Operator & CRD                       | `true`                       |
| `wpokOperator.pvc.enabled`                  | Create a PVC for worker scratch                             | `true`                       |
| `wpokOperator.resourceQuota.enabled`        | Create a namespace ResourceQuota                            | `true`                       |
| `wpokOperator.resourceQuota.cpuRequests`    | CPU requests hard cap                                       | `"8"`                        |
| `wpokOperator.resourceQuota.memoryRequests` | Memory requests hard cap                                    | `"8Gi"`                      |
| `wpokOperator.resourceQuota.cpuLimits`      | CPU limits hard cap                                         | `"8"`                        |
| `wpokOperator.resourceQuota.memoryLimits`   | Memory limits hard cap                                      | `"8Gi"`                      |
| `wpokOperator.image`                        | Operator image                                              | `worker-pool-operator:0.2.6` |

See `values.yaml` for the complete list, including Keda/RabbitMQ/Redis resource requests/limits and S3/MinIO settings used by workers.

---

## Notes on Template Configuration

* WorkerPool children (`Deployment`, `ScaledObject`, `PrometheusRule`) are defined under `wpokOperator.templates` in `values.yaml` and shipped to the operator via a ConfigMap mounted at `/templates`.
* You can copy and modify the defaults to tailor worker environment variables, resource requests, HPA behaviour (via Keda), or Prometheus rules for scaling.
* When you change templates, run `helm upgrade` (and restart the operator if it doesn’t hot‑reload).

---

## CRD Management

By default the chart installs/updates the `WorkerPool` CRD. If a compatible CRD already exists (installed elsewhere), set:

```yaml
crds:
  create: false
```

> Uninstalling the release does **not** remove the CRD; delete it manually if required.

---

## Uninstalling

```bash
helm uninstall wpok -n wpok
```

If you enabled CRD installation originally and want to remove it as well:

```bash
kubectl delete crd workerpools.hyperflow.agh.edu.pl
```

