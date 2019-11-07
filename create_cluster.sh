#!/bin/bash

# Create network
docker network create k8s-net

# Create control-plane
docker run -d --privileged --network k8s-net --name master icebert/kubernetes-in-docker

docker exec master kubeadm init --ignore-preflight-errors all \
                                --pod-network-cidr 10.244.0.0/16 \
                                --token dzsner.a8tyt63f4hbs2ukz \
                                --image-repository gcr.azk8s.cn/google_containers

docker exec master sh -c "kubectl get configmap -n kube-system coredns -o yaml | sed '/loop/d' | kubectl replace -f -"

# Create pod network
docker exec master kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter-all-features.yaml
docker exec master kubectl -n kube-system delete ds kube-proxy

# Create worker nodes
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



