#!/bin/bash
echo "=======> disabeling swap :"
swapoff -a

echo "=======> updating repos :"
apt update
echo "=======> installing curl, gnupg & software-properties-common :"
apt -y install curl gnupg software-properties-common
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

echo "=======> setting hostname to main :"
hostnamectl set-hostname main

echo "=======> initializing kubeadm :"
kubeadm init

echo "=======> copying config file :"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "=======> adding calico networking solution :"
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml

echo "=======> generating kubejoin.sh :"
printf %"s\n" \
"swapoff -a" \
"echo y | kubeadm reset" \
"systemctl restart kubelet" \
"`kubeadm token create --print-join-command`" \
"echo \"kubelet status\" :" \
"systemctl status kubelet | head -5 | tail -1"> kubejoin.sh

echo "=======> installing nginx to publish kubejoin.sh to worker nodes :"
apt install -y nginx
cat kubejoin.sh > /var/www/html/kubejoin.sh

echo "=======> waiting for at least one worker to join the cluster :"
while [[ `kubectl get nodes | tr -s ' ' | cut -d ' ' -f 2 | sed 1,1d | grep "^Ready" | wc -l` -lt 2 ]]; do sleep 5; done

echo "=======> installing helm :"
curl https://helm.baltorepo.com/organization/signing.asc | sudo apt-key add -
apt install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt update
apt install -y helm

echo "=======> installing jenkins :"
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
wget https://raw.githubusercontent.com/mdnfiras/devops-infra/master/jenkins/jenkins-values.yaml
helm install cd-jenkins -f jenkins-values.yaml stable/jenkins --version 1.2.2

