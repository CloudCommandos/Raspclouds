# Container Orchestrator
Docker provides the platform to build, ship and run containers. However, what happens when you have multiple containers that you would like to run across multiple servers? Manually managing all the containers manually would be a tedious work. To resolve this issue, container orchestrator comes into play.

Container orchestrator automates the process of deployment, management, networking, scaling and availability of the containers.

Some of the features that a container orchestrator have that Docker does not.

* Container scheduling
* Service discovery
* Redundancy and availability of containers
* Scaling up or down on the containers when required
* Monitoring the health status of the containers and host machines
* Migrate containers on a failed node to other available node
* Load Balancing

## Comparison on the Big Three Container Orchestrators
**Docker Swarm**
* Integrated with docker package version 1.12
* Easy to setup but limited customisation
* Suitable for small scale systems
* Flexible to change manager and worker nodes. Easy to promote or demote nodes between the roles
* Scaling has to be done with third-party application
* Yet to support external load balancing

**Kubernetes**
* Highly versatile and allow more customisation
* Web UI available
* Uses YAML or JSON for deployment
* Large open source community
* Require more details on setting up the cluster. Need to specific on the amount of nodes in the cluster and choose a master node among the cluster
* Auto-scaling
* Require less third-party software compared to Swarm and Mesos
* Flexible to deploy Kubernetes on any cloud or pre-existing data center

**Mesos**
* Good for large system and maximum redundancy. Able to run up to 50,000 nodes
* Used by companies like Airbnb and Twitter
* Require Marathon Framework for container orchestrator to work
* Uses Zookeeper to form High-Availability cluster
* Complexity and Flexibility

# Kubernetes
Kubernetes is the container orchestrator that automates the deployment, scaling and management of containers.

Some key features of Kubernetes are:

* Deploy multi-container application
* Provide networking, storage and service discovery
* Rolling on updates without any downtime

A standard Kubernetes setup consists of both master and worker nodes. A master node consists of 3 applications, API server, controller manager and scheduler. Kubernetes API uses command line `kubectl` to describe the desired state.

The worker node consists of 2 processes, kubelet and a proxy (kube-proxy). Kubelet is a "node agent" that starts and stops the pods and communicates with Docker Engine at a host level. Kubelet also communicates with API server on the master nodes and manages the containers, associated volumes and images. Kube-proxy reflects the kubernetes networking service on each node.

Common terms of Kubernetes:

Node: It a worker machine and it maybe either a physical machine or a virtual machine. A Master node controls each worker nodes. A node consists of at least a container runtime and Kubelet.

An example of container runtime is docker for pulling of image, unpacking and running the application. Kubelet is responsible for the communication between the master and worker nodes. It also manages the pods and containers running on the node.

Pod: A pod is a host application instances that can host a single or multiple containers and storage volumes. Pod has a unique IP address within its cluster and information on how to run container, container image version, specific ports to use etc. Data stored in the pod are not persistent and pod always runs on a node.

To list the pods, use `kubectl get pods`. `kubectl describe pods` will show the details on the pod's container such as container ID, IP address etc.

Although pods have IP addresses, but the IP addresses are not exposed outside of the cluster without a Service. Service is required to allow the application to receive traffic.

Here are some of the type of Services available:

1. ClusterIP - By default. This service is only reachable within the cluster.
1. NodePort - Expose the port of each selected node in the cluster via NAT. This makes the service accessible from the outside cluster using NodeIP:NodePort.
1. LoadBalancer - Create an external load balancer in the cloud and assigned it with a fixed external IP address to the service.


 To update container, `kubectl set image nameofdeployment container:version`

 To check the status of the rollout, `kubectl rollout status nameofdeployment`

 To undo a rollout, `kubectl rollout undo nameofdeployment`

 ## Installing Kubernetes
 Before installing Kubernetes, we must first install [Docker](https://docs.docker.com/install/linux/docker-ce/debian/#set-up-the-repository).

 To install Kubernetes enter the following commands:
```bash
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

Some of the minimum requirement to take note for installing Kubernetes:
1. 2 CPUs or more
1. 2GB or more of RAM
1. Ensure connectivity between the machine in the cluster
1. Swap must be disabled

To disable swap. Enter `swapoff -a` and this will disable swap but this is not persistent. Thus, to disable swap persistently, edit `/etc/fstab` and remove or comment out the line on swap.

Choose a pod network add-on before initialising the master node. The pod network is required for the pods to communicate with each other. A list of pod network is available [here](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)

For this installation, Flannel will be used as the pod network. Thus, the command to initialise is
```bash
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=masteripaddresstocluster
```
The argument `--pod-network-cidr=10.244.0.0/16` is for Flannel setup.

`--apiserver-advertise-address=` is to be set with the master node IP adddress that has connection with the rest of the nodes in the cluster.

For Flannel, enter `sysctl net.bridge.bridge-nf-call-iptables=1` to pass bridged IPv4 traffic to  iptables chain.

After the initialisation is completed, remember to take down the command to add nodes to the master. The command should be display on the last line once the initialisation is completed. Example of the command with the token and cert:
```bash
kubeadm join 192.168.1.2:6443 --token 5dbj06.mbyb1suo8epe841a --discovery-token-ca-cert-hash sha256:0eb04182eea1061a0bd10a024b261e9eabd8e58e57bb99837938cd0c39138721
```
By default, the tokens expire after 24 hours. If the token expired, use the following command to create another token and print the join command:
```bash
kubeadm token create --print-join-command
```
For non-root user to run kubectl, enter the following commands:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
For root user, enter the following command:
```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```
The above command can also resolve if error `The connection to the server localhost:8080 was refused - did you specify the right host or port?` is encountered.

Lastly, to finish up the configuration of the master node, we need to add the network driver. The driver should be selected during the `kubeadm init`. For this setup, Flannel is used and the command to add Flannel is:
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
```

Enter `kubectl get nodes` to check if your master node is correctly setup. The status for the node should be Ready and Roles should be master.
Example of the output for `kubectl get nodes`:
```
NAME     STATUS   ROLES    AGE   VERSION
master   Ready    master   48m   v1.13.0
```

Once the master status is ready, you can now go to each nodes and enter the command to join the cluster as shown above, 'kubeadm join ...'. Below shows an example of the output command `kubectl get nodes`, with a 3 nodes cluster.
```bash
NAME     STATUS   ROLES    AGE   VERSION
master   Ready    master   18h   v1.13.0
node1    Ready    <none>   18h   v1.13.1
node2    Ready    <none>   18h   v1.13.1
node3    Ready    <none>   18h   v1.13.1
```

## Centralised Logging

To monitor individual nodes can be a hectic job. With a centralised logger, it easy for administrator to monitor all the nodes. One of the common logging stack in kubernetes is Elasticsearch, Fluentd and Kibana aka EFK.

EFK is comprised of:

* **Elasticsearch** is a distributed search and analytics engine, an object store where all logs are stored.
* **Fluentd** gathers logs from each nodes and forward it to Elasticsearch
* **Kibana** is a web UI to visualise the Elasticsearch data

Fluentd will be deployed on all the nodes in the cluster and aggregate the logs. Application in docker container writes stdout/stderr logs and stores in `/var/log/containers` directory.    
​Thereafter, Fluentd will forward the log to the node where Elaasticsearch is hosted. Kibana will access Elasticsearch data and provide a visualisation of the logs collected.

There are YAML files to configure the EFK stack in the Kubernetes GitHub [repository](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch).

You can either clone the whole repository down and run with `kubectl apply -f` or use `kubectl apply -f https://urloftheyaml` to run the YAML file for the EFK stack. In this case, the repository is clone to the master node.

Firstly, the first YAML to run is the `es-statfulset.yaml` file. Do take note that this script does not configure the logs to be stored in a persistent volume. Thus, the logs will be erased when the pods terminates.

To configure a **local** persistent volume, add the following script to the `es-statfulset.yaml` or a separate YAML file to create persistent volume. In this case, the script is added to the existing `es-statfulset.yaml` file. Add the script before the deployment of Elasticsearch.
Change the size of the storage to your own preference. As the `es-statfulset.yaml` application is created in the namespace `kube-system`, same namespace has to be used for the PersistentVolume and PersistentVolumeClaim. The hostPath define the directory on where the logs should be stored in the node.
```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  namespace: kube-system
  name: elasticsearch-volume
  labels:
    type: local
spec:
  storageClassName: elasticsearch
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: "/mnt/data/elasticsearch"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: kube-system
  name: elasticsearch-pv-claim
  labels:
    app: elasticsearch-logging
spec:
  storageClassName: elasticsearch
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
```

Next, editing the following lines in the `es-statfulset.yaml`.
```yaml
volumes:
- name: elasticsearch-logging
  emptyDir: {}
```
and replace it the following:
```yaml
volumes:
- name: elasticsearch-logging
  persistentVolumeClaim:
    claimName: elasticsearch-pv-claim
```

Alternatively, if you are using **Ceph** for your storage, you can add the following lines. Change the IP address accordingly to your Ceph configurations.
```yaml
volumes:
- name: elasticsearch-logging
  cephfs:
    monitors:
      - 192.168.2.3:6789
      - 192.168.2.4:6789
      - 192.168.2.5:6789
    user: admin
    secretRef:
      name: cephfs-pass
    readOnly: false
    path: "/"
```

For a single master node, you might encounter an error for your elasticsearch-logging even though the status is running and Kibana web interface shows`plugin:elasticsearch@6.3.2 	Service Unavailable`  

Do a `kubectl logs elasticsearch-logging-0 -n kube-system` to check for error
```
[WARN ][o.e.d.z.ZenDiscovery     ] [elasticsearch-logging-0] not enough master nodes discovered during pinging (found [[Candidate{node={elasticsearch-logging-0}{Wc2Yr6gNSsibEjP2CXoTdw}{i6xd9Gt9Q-m14F-ZP0ZIng}{10.244.2.185}{10.244.2.185:9300}, clusterStateVersion=-1}]], but needed [2]), pinging again
```

If the above error is shown, this can be resolved by add the following two lines to your env section of `es-statefulset.yaml` file.
```yaml
   env:
   ...
   - name: discovery.zen.minimum_master_nodes #added
     value: "1" #added
```
Once completed, run
```bash
kubectl apply -f es-statfulset.yaml
```
Run the following command to check the status of deployment of elasticsearch:
```bash
kubectl get pods -l k8s-app=elasticsearch-logging -n kube-system
```
If the deployment is successful, you should see the following if the replicas is set as 2:
```
NAME                      READY   STATUS    RESTARTS   AGE
elasticsearch-logging-0   1/1     Running   0          10s
elasticsearch-logging-1   1/1     Running   0          27s
```

Run the next YAML file to create a service for the elasticsearch-logging
```bash
kubectl apply -f es-service.yaml
```
Verify the deployment with the following:
```bash
kubectl get svc -l k8s-app=elasticsearch-logging -n kube-system
```

```
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
elasticsearch-logging   ClusterIP   10.99.68.245   <none>        9200/TCP   44s
```

Next, let's deploy Fluentd as DaemonSet which will deploy it on all the nodes in the cluster. Note: The existing fluentd deployment YAML file from kubernetes GitHub repository seems to have some issue and the status of the deployment shows that there is a CrashLoopBackOff issue. More details on the issue is as shown below. Thus, another repository is been used to deploy fluentd.
```bash
kubectl logs fluentd-es-v2.2.1-8dr56 -n kube-system


2019-01-03 08:03:51 +0000 [error]: config error file="/etc/fluent/fluent.conf" error_class=Fluent::ConfigError error="Unknown filter plugin 'concat'. Run 'gem search -rd fluent-plugin' to find plugins"
```

Run the following command for fluentd configurations:
```bash
kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/efk-stack/master/fluentd-es-configmap.yaml
```

Side note: If you are using the kubernetes GitHub `fluentd-es-ds/yaml`, comment out the following lines to allow fluentd to be deployed on all nodes within the cluster:
```yaml
nodeSelector:
  beta.kubernetes.io/fluentd-ds-ready: "true"
```

Run the following command:
```bash
kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/efk-stack/master/fluentd-es-ds.yaml
```

Verify the fluentd deployment with the following command:
```bash
kubectl get pods -n kube-system -l k8s-app=fluentd-es
```
If the deployment is successful, you should see the following for a cluster with 3 worker nodes:
```
NAME                      READY   STATUS    RESTARTS   AGE
fluentd-es-v2.2.0-8hmg4   1/1     Running   0          5s
fluentd-es-v2.2.0-qvsp5   1/1     Running   0          5s
fluentd-es-v2.2.0-vxchh   1/1     Running   0          5s
```

Lastly, lets deploy Kibana.
```bash
kubectl apply -f kibana-deployment.yaml
```

Verify the deployment with the following command:
```bash
kubectl get pods  -n kube-system -l k8s-app=kibana-logging
```
The output should be as of follows:
```
NAME                              READY   STATUS    RESTARTS   AGE
kibana-logging-764d446c7d-jp6gk   1/1     Running   0          2m29s
```

Now, run the `kibana-service.yaml` to deploy kibana service.
```bash
kubectl apply -f kibana-service.yaml
```
Verify the service deployment with the following command:
```bash
kubectl get svc  -n kube-system -l k8s-app=kibana-logging
```
The output of the above command should be:
```
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kibana-logging   ClusterIP   10.109.171.94   <none>        5601/TCP   3s
```

Once the service is up, create an ingress yaml and name it `deployIngressKibana.yaml` and run the ingress yaml.
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-kibana
  namespace: kube-system
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: node1
    http:
      paths:
      - path: /*
        backend:
          serviceName: kibana-logging
          servicePort: 5601
```

```bash
kubectl apply -f deployIngressKibana.yaml
```
Use `kubectl get ingress --all-namespaces` to check for the ingress deployed.


Now you can open up a browser and enter the your domain name specified in the `deployIngressKibana.yaml` host.

If you encounter a issue that shows `{"statusCode":404,"error":"Not Found","message":"Not Found"}` when you open up the site, comment off the following line in `kibana-deployment.yaml`.
```bash
- name: SERVER_BASEPATH
  value: /api/v1/namespaces/kube-system/services/kibana-logging/proxy
```

## Centralised Monitoring
Monitoring the kubernetes cluster is critical for the system administrator. Monitoring provides the platform to understand what is going on inside the system, the performance of the system, how many errors are there etc. One popular monitoring stack is the [Prometheus Stack](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus). Prometheus server will utilise service discovery in your cluster and connect to them and pull the metrics from your applications.


Here are some of the applications within the Prometheus monitoring stack:
1. Prometheus - Pull and storing of data in time-series format which are identified by metric name and key/value pairs
1. Grafana -  Provides web user interface for visualisation and monitoring dashboard for the data collected from Prometheus server
1. Alertmanager - Sends out notification via various channel such as email, to notify users of alerts.
1. Node-exporter - Collects system metrics such as cpu, memory, disk and expose them  where Prometheus server will pull the metrics

To start using Prometheus in your kubernetes cluster, `git clone https://github.com/coreos/prometheus-operator.git` the [Prometheus repository](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) from Coreos GitHub to your master node.

change your directory to `prometheus-operator/contrib/kube-prometheus/`.

Enter the following to deploy Prometheus stack:
```bash
kubectl apply -f manifests/
```

Note: run the command twice if errors are shown during the deployment.

Run `kubectl get pods -n monitoring` to check the list of pods deployed for Prometheus stack. An example of `kubectl get pods -n monitoring` for a master and 3 worker nodes cluster shown below.
```
NAME                                   READY   STATUS    RESTARTS   AGE
alertmanager-main-0                    2/2     Running   0          23h
alertmanager-main-1                    2/2     Running   0          23h
alertmanager-main-2                    2/2     Running   0          23h
grafana-777cf74b98-tgt9s               1/1     Running   0          23h
kube-state-metrics-76b8dd6dd-44jn2     4/4     Running   0          23h
node-exporter-9dtvp                    2/2     Running   0          23h
node-exporter-cwdzp                    2/2     Running   0          23h
node-exporter-wzxmq                    2/2     Running   2          23h
node-exporter-xsp6t                    2/2     Running   0          23h
prometheus-adapter-66fc7797fd-pf92l    1/1     Running   0          23h
prometheus-k8s-0                       3/3     Running   1          23h
prometheus-k8s-1                       3/3     Running   1          23h
prometheus-operator-7df4c46d5b-gzqcs   1/1     Running   0          23h
```
Node-exporter is deployed as DaemonSet, which will be deployed in all nodes within the cluster.

Make sure all the pods in namespace `monitoring` are running. Next, Prometheus, grafana and alertmanager all have dashboard for web user interface. Do a quick port forwarding on your localhost to check if the applications are working with either your web browser or `curl` function.

To access Prometheus dashboard, enter the following:
```bash
kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
```
To accesss Grafana dashboard, enter the following:
```bash
kubectl --namespace monitoring port-forward svc/grafana 3000
```
To accesss Alertmanager dashboard, enter the following:
```bash
kubectl --namespace monitoring port-forward svc/alertmanager-main 9093
```

Use `http://localhost:portnumber` to access the web interface or `curl http://localhost:portnumber` which will out put `<a href="/graph">Found</a>.` if deployment is successful. The port numbers for each applications are as followed:

| Application | Port Number |
| --- | --- |
| Prometheus | 9090 |
| Grafana | 3000 |
| Alertmanager | 9093 |

To deploy Prometheus stack with Ingress Controller, we need to create an ingress yaml. The `hostname/subdomainname` can be your hostname of your worker node in `/etc/hosts` or the sub-domain of your site.
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-pga
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: hostname/subdomainname
    http:
      paths:
      - path: /*
        backend:
          serviceName: prometheus-k8s
          servicePort: 9090
  - host: hostname/subdomainname
    http:
      paths:
      - path: /*
        backend:
          serviceName: grafana
          servicePort: 3000
  - host: hostname/subdomainname
    http:
      paths:
      - path: /*
        backend:
          serviceName: alertmanager-main
          servicePort: 9093
````

Now you can use the hostname/sub to access the web interface. You can now use Grafan to monitoring the status of your kubernetes cluster!

If you would like to store the data to a persistent volume, head over [here](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md) to view the instructions.
