#!/bin/bash

# https://kubernetes.io/docs/setup/independent/install-kubeadm/

export PATH="$PATH:/opt/bin"
echo '127.0.0.1 master-1' >> /etc/hosts

# Install CNI plugins
CNI_VERSION="v0.6.0"
mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz

# Install crictl
CRICTL_VERSION="v1.11.1"
mkdir -p /opt/bin
curl -L "https://github.com/kubernetes-incubator/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C /opt/bin -xz

# Install kubeadm, kubelet, kubectl and add a kubelet systemd service:
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

mkdir -p /opt/bin
cd /opt/bin
curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
chmod +x {kubeadm,kubelet,kubectl}

curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubelet.service" | sed "s:/usr/bin:/opt/bin:g" > /etc/systemd/system/kubelet.service
mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/10-kubeadm.conf" | sed "s:/usr/bin:/opt/bin:g" > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

#KUBEVER=1.13.1-00
#LBIP=192.168.50.10
#LBDNS="k8s.local"
CLUSTERIP="10.32.0.10"
IP=$(ifconfig eth1 | grep 'inet ' | awk '{print $2}')
CGD=$(docker info | grep cgroup | awk '{print $3}')
echo "KUBELET_EXTRA_ARGS=\"--cgroup-driver=$CGD --node-ip=$IP --cluster-dns=$CLUSTERIP\"" > /etc/default/kubelet

# Specify cgroup driver
echo "DOCKER_CGROUPS=\"--exec-opt native.cgroupdriver=systemd\"" >> /run/metadata/torcx
systemctl enable docker && systemctl restart docker

# Enable kublet
systemctl enable kubelet && systemctl start kubelet

# Init kubeadm
SHAREDIR=/home/core/share
kubeadm init --config=$SHAREDIR/weave/kubeadm-config.yaml | tee $SHAREDIR/shared/kubeadm-init.log
#$SHAREDIR/provision/setup-kubectl.sh
#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
