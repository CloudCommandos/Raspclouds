# Monitoring

## Monitoring Kubernetes Cluster

To monitor the status of the kubernetes cluster, [kube-prometheus](https://github.com/coreos/kube-prometheus) aka prometheus operator can be deployed in the cluster for monitoring. Kube-prometheus contains the prometheus stack, including Grafana for visualization of the metrics and Alertmanager for sending out notification.

Git clone the kube-prometheus repositary and deploy the manifests folder. Once deployed, the prometheus stack will start to monitor the kubernetes cluster. Each applications in prometheus stack have its own GUI. In this instance, Ingress Controller will be used to direct to each prometheus stack's applications GUI. An example of a ingress file for prometheus stack can be found [here]().

## Customise Kube-Prometheus

With kube-prometheus, it comes with pre-configured configurations, such as prometheus alert rules, grafana dashboard etc.

The content of project kube-prometheus is created with a sets of jsonnet files. The following needs to be installed to [customise kube-prometheus](https://github.com/coreos/kube-prometheus#customizing-kube-prometheus):
* Golang
* [Jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler#install)
* jsonnet
* gojsontoyaml

To install Golang, enter `apt-get install golang`. Once installed, create a directory with this command `mkdir ~/go`. In Debian platform, copy and paste these lines to `~/.profile` to [set the GOPATH](https://github.com/golang/go/wiki/SettingGOPATH).
```
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
```

Next, to install jsonnet-bundler, jsonnet and gojsontoyaml.
```
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
go get github.com/google/go-jsonnet/cmd/jsonnet
go get github.com/brancz/gojsontoyaml
```

Refer to [here](https://github.com/jsonnet-bundler/jsonnet-bundler#install) for jb installation.

Once the 2 packages are installed, following this instruction [here](https://github.com/coreos/kube-prometheus#installing).

Download or copy [example.jsonnet](https://github.com/coreos/kube-prometheus/blob/master/example.jsonnet) to start customising kube-prometheus. Next download the [script](https://github.com/coreos/kube-prometheus/blob/master/build.sh) to build the kube-prometheus manifests files with the customised example.jsonnet.

To run the script on a Debian platform, enter ` bash ./build.sh example.jsonnet`. The script will now build the new kube-prometheus with the customised setting.

The following lines were added to example.jsonnet to monitor FreeBSD platoform for high cpu usage, high memory usage and disk capacity. These lines will be added to prometheus-rules.yaml and it will trigger when the expr condition is met.
```
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
```

To add a Grafana json file to add in  new dashboard, add the following lines. Note: Json file needs to be in the same directory as example.jsonnet.

```
grafanaDashboards+:: {
 'dashboard-example.json': (import 'dashboard-example.json'),
},
```


## Monitoring NGINX Ingress Controller

Monitoring the Ingress controller allow users status such as amount of request going in/out of the controller.
In NGINX ingress controller deployment file, there is an option to expose Prometheus metrics.
```yaml
annotations:
  prometheus.io/port: "10254"
  prometheus.io/scrape: "true"
```

with the option show above, the NGINX ingress controller will expose Prometheus metrics. Additional, add another port to expose the containerPort of ingress controller.
```
- name: metrics
  containerPort: 10254
```

Next, create additional service to expose the port **10254** to external.
```
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx-metrics
    app.kubernetes.io/part-of: ingress-nginx-metrics
  name: ingress-nginx-metrics
  namespace: ingress-nginx
spec:
  ports:
  - name: metrics
    port: 10254
    targetPort: metrics
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
```

In order for Prometheus to scrape the metrics from ingress controller, a serviceMonitor object is required. Note: the selector matchLabels need to match with the service object labels.
```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
  name: ingress-nginx
  namespace: monitoring
spec:
  endpoints:
  - interval: 15s
    port: metrics
    #jobLabel: ingress-nginx
  namespaceSelector:
    matchNames:
    - ingress-nginx
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx-metrics
      app.kubernetes.io/part-of: ingress-nginx-metrics
```

With kube-prometheus, it is also required to add in the namespace for the ingress controller to allow Prometheus to scrape from ingress controller metrics.

Navigate to kube-prometheus manifests files and look for prometheus-roleSpecificNamespaces.yaml and prometheus-roleBindingSpecificNamespaces.yaml. In this instance, the namespace where ingress controller is deployed is in **ingress-nginx**

Add in the following to prometheus-roleSpecificNamespaces.yaml.
```
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: prometheus-k8s
    namespace: ingress-nginx
  rules:
  - apiGroups:
    - ""
    resources:
    - services
    - endpoints
    - pods
    verbs:
    - get
    - list
    - watch
  ```

  Add in the following to prometheus-roleBindingSpecificNamespaces.yaml.
  ```
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: prometheus-k8s
      namespace: ingress-nginx
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: prometheus-k8s
    subjects:
    - kind: ServiceAccount
      name: prometheus-k8s
      namespace: monitoring
```

If all the above are done correctly, Prometheus will now be able to scrape the metrics from ingress controller and appear under Targets or Service Discovery in Prometheus GUI.
