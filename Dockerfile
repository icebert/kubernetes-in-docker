FROM solita/ubuntu-systemd
LABEL description "kubernetes in docker"

RUN apt-get update && apt-get install -y \
    apt-transport-https ca-certificates curl gnupg-agent software-properties-common

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" && \
    apt-get update && apt-get install -y \
    docker-ce=5:18.09.9~3-0~ubuntu-xenial docker-ce-cli=5:18.09.9~3-0~ubuntu-xenial containerd.io

RUN curl -fsSL http://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main" && \
    apt-get update && apt-get install -y \
    kubelet kubeadm kubectl

RUN apt-get install -y linux-image-$(uname -r)

RUN mkdir -p /etc/docker && \
echo '\
{\n\
    "exec-opts": ["native.cgroupdriver=cgroupfs"],\n\
    "log-driver": "json-file",\n\
    "log-opts": {\n\
        "max-size": "100m"\n\
    },\n\
    "storage-driver": "aufs"\n\
}\n\
' > /etc/docker/daemon.json && \
mkdir -p /etc/systemd/system/docker.service.d && \
sysctl fs.inotify.max_user_watches=1048576


ENV KUBECONFIG /etc/kubernetes/admin.conf

EXPOSE 6443 10250 10251 10252

VOLUME [ "/mnt", "/var/lib/docker" ]

CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]

