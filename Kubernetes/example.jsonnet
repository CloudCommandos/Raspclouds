local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-thanos.libsonnet') +
{
_config+:: {
   namespace: 'monitoring',
},
grafanaDashboards+:: {
'firewall-node-exporter.json': (import 'firewall-node-exporter.json'),
},
prometheusAlerts+:: {
groups+: [
 {
   name: 'external-node',
   rules: [
     {
       alert: 'InstanceDown',
       annotations: {
         message: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 3 minutes.',
       },
       expr: 'up == 0',
       'for': '3m',
       labels: {
         severity: 'warning',
       },
     },
     {
       alert: 'CPUThresholdExceeded',
       annotations: {
         message: 'This device CPU usage has exceeded the thresold of 90% with a value of {{ $value }} for 3 minutes.',
       },
       expr: '100 - (avg by (instance) (irate(node_cpu_seconds_total{job="firewall-node-exporter",mode="idle"}[5m])) * 100) > 90',
       'for': '3m',
       labels: {
         severity: 'warning',
       },
     },
     {
       alert: 'MemoryUsageWarning',
       annotations: {
         message: 'This device Memory usage has exceeded the thresold of 80% with a value of {{ $value }} for 5 minutes.',
       },
       expr: '((node_memory_size_bytes - (node_memory_free_bytes + node_memory_cache_bytes + node_memory_buffer_bytes) ) / node_memory_size_bytes) * 100  > 80',
       'for': '5m',
       labels: {
         severity: 'warning',
       },
     },
      {
        alert: 'DiskSpaceWarning',
        annotations: {
          message: 'This device Disk usage has exceeded the thresold of 75% with a value of {{ $value }}.',
        },
        expr: '100 -  ((node_filesystem_free_bytes  * 100 / node_filesystem_size_bytes))  > 75',
        'for': '60m',
        labels: {
          severity: 'warning',
        },
      },
   ],
 },
],
},
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
