#!/bin/bash
echo "=======> disabeling swap :"
swapoff -a

echo "=======> updating repos :"
apt update
echo "=======> installing curl, gnupg, software-properties-common & resolvconf :"
apt -y install curl gnupg software-properties-common resolvconf
echo "=======> setting up dns :"
systemctl start resolvconf.service
systemctl enable resolvconf.service
echo "nameserver 192.168.5.3" >> /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf.service
echo "=======> updating repos :"
apt update
echo "=======> installing docker.io :"
apt -y install docker.io
echo "=======> starting docker :"
systemctl start docker
echo "=======> enabeling docker :"
systemctl enable docker
echo "=======> checking docker status :"
systemctl status docker | head -3 | tail -1

echo "=======> adding kubernetes repo :"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
echo "=======> updating repos :"
apt update
echo "=======> installing kubeadm, kubelet, kubectl & kubernetes-cni :"
apt -y install kubeadm kubelet kubectl kubernetes-cni

echo "=======> waiting for main node and DNS server to be ready :"
while [[ "$(curl -o /dev/null -u myself:XXXXXX -Isw '%{http_code}\n' http://devops.[[DOMAIN]]/kubejoin.sh)" != "200" ]]; do sleep 5 ; done

echo "=======> downloading kubejoin.sh :"
wget http://devops.[[DOMAIN]]/kubejoin.sh

echo "=======> running kubejoin.sh :"
chmod u=rx kubejoin.sh
./kubejoin.sh

echo "=======> installing package for NFS client :"
apt install -y nfs-common

echo "=======> finished !"