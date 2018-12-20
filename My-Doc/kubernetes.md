# Container Orchestrator
Docker provides the platform to build, ship and run containers. However, what happen when you have multiple containers that you would like to run across multiple servers. Manually managing all the containers manually would be a tedious work. To resolve this issue, container orchestrator comes in play.

Container orchestrator automates the process of deployment, management, networking, scaling and availability of the containers.

Some of the features that a container orchestrator have that Docker doesn't.

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

The worker node consists of 2 processes, kubelet and a proxy (kube-proxy). Kubelet is a "node agent" that start and stop the pods and communicates with Docker Engine at a host level. Kubelet also communicate with API server on the master nodes and manages the containers, associated volumes and images. Kube-proxy reflects the kubernetes networking service on each node.

Common terms on Kubernetes:

Node: It a worker machine and it maybe either a physical machine or a virtual machine. A Master node controls each worker nodes. A node consists of at least a container runtime and Kubelet.

An example of container runtime is docker for pulling of image, unpacking and running the application. Kubelet is responsible for the communication between the master and worker nodes. It also manages the pods and containers running on the node.

Pod: A pod is a host application instances that can host a single or multiple containers and storage volumes. Pod has a unique IP address within its cluster and information on how to run container, container image version, specific ports to use etc. Data stored in the pod are not persistent and pod always runs on a node.

To list the pods, use `kubectl get pods`. `kubectl describe pods` will show the details on the pod's container such as container ID, IP address etc.

Although pods have IP addresses, but the IP addresses are not exposed outside of the cluster without a Service. Service is required to allow the application to receive traffic.

Here are some of the type of Service available:

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
debian   Ready    master   48m   v1.13.0

```
