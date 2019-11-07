# kubernetes in docker

Using docker containers as virtual machines to compose a cluster and run kubernetes in it

---

The `create_cluster.sh` script creates a kubernets cluster with one master node and three worker nodes.

First, create a user defined network so that we can reach each node with its name instead of its ip address.

```shell
docker network create k8s-net
```

Next, create the control-plane

```shell
docker run -d --privileged --network k8s-net --name master icebert/kubernetes-in-docker


docker exec master kubeadm init --ignore-preflight-errors all \
                                --pod-network-cidr 10.244.0.0/16 \
                                --token dzsner.a8tyt63f4hbs2ukz
```

Edit the coredns configmap to remove loop detection to fix coredns running into CrashLoopBackOff state

```shell
docker exec master sh -c "kubectl get configmap -n kube-system coredns -o yaml | sed '/loop/d' | kubectl replace -f -"
```

Create the pod network, use kube-router with all features to replace kube-proxy. Because the docker container does not have `/proc/sys/net/bridge/bridge-nf-call-iptables`, the kube-proxy would fail to start.

```shell
docker exec master kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter-all-features.yaml
docker exec master kubectl -n kube-system delete ds kube-proxy
```

Finally, create 3 worker nodes

```shell
docker run -d --privileged --network k8s-net --name worker0 icebert/kubernetes-in-docker
docker run -d --privileged --network k8s-net --name worker1 icebert/kubernetes-in-docker
docker run -d --privileged --network k8s-net --name worker2 icebert/kubernetes-in-docker

docker exec worker0 kubeadm join master:6443 --token dzsner.a8tyt63f4hbs2ukz \
                                             --discovery-token-unsafe-skip-ca-verification \
                                             --ignore-preflight-errors all
docker exec worker1 kubeadm join master:6443 --token dzsner.a8tyt63f4hbs2ukz \
                                             --discovery-token-unsafe-skip-ca-verification \
                                             --ignore-preflight-errors all
docker exec worker2 kubeadm join master:6443 --token dzsner.a8tyt63f4hbs2ukz \
                                             --discovery-token-unsafe-skip-ca-verification \
                                             --ignore-preflight-errors all
```

The kubernetes cluster should be ready now.

