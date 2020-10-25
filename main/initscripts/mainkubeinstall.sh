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

echo "=======> installing package for NFS client :"
apt install -y nfs-common

echo "=======> waiting for DNS and NFS servers to be ready :"
while [[ -z "$(ping nfs.[[DOMAIN]] -c 1 | grep 0% )" ]]; do sleep 5; done

echo "=======> mounting via NFS :"
mkdir -p /mnt/nfs_k8s
mount nfs.[[DOMAIN]]:/mnt/nfs_share /mnt/nfs_k8s

echo "=======> sharing kubejoin.sh to worker nodes via NFS :"
mkdir -p /mnt/nfs_k8s/kubejoin
chmod ugo=rwx /mnt/nfs_k8s/kubejoin
cp kubejoin.sh /mnt/nfs_k8s/kubejoin/kubejoin.sh
chmod ugo=r /mnt/nfs_k8s/kubejoin/kubejoin.sh

echo "=======> waiting for at least one worker to join the cluster :"
while [[ `kubectl get nodes | tr -s ' ' | cut -d ' ' -f 2 | sed 1,1d | grep "^Ready" | wc -l` -lt 2 ]]; do sleep 5; done

echo "=======> [metallb] installing metallb :"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

echo "=======> [metallb] configuring the loadbalancer's addresses pool :"
kubectl apply -f metallb/metallb-config.yaml

echo "=======> [nginx-ingress] installing nginx ingress controller :"
kubectl apply -f nginx-ingress-controller/nginx-ingress-deployment.yaml

echo "=======> [nginx-ingress] waiting for nginx-ingress' create job to finish :"
while [[ -z "`kubectl get pods -n ingress-nginx | grep create | grep Completed`" ]]; do sleep 5; done

echo "=======> [nginx-ingress] waiting for nginx-ingress' patch job to finish :"
while [[ -z "`kubectl get pods -n ingress-nginx | grep patch | grep Completed`" ]]; do sleep 5; done

echo "=======> [nginx-ingress] waiting for nginx-ingress' pod to run :"
while [[ -z "`kubectl get pods -n ingress-nginx | grep controller | grep Running`" ]]; do sleep 5; done

echo "=======> [nginx-ingress] waiting for nginx-ingress' deployment :"
while [[ -z "`kubectl get deployments -n ingress-nginx | grep "1/1"`" ]]; do sleep 5; done

echo "=======> [nginx-ingress] waiting for ingress-nginx-controller-admission service to run :"
while [[ -z "`kubectl get services -n ingress-nginx | grep ingress-nginx-controller-admission`" ]]; do sleep 5; done

echo "=======> [jenkins] preparing directory for persistent volume over NFS :"
mkdir -p /mnt/nfs_k8s/jenkins
chmod ugo=rwx /mnt/nfs_k8s/jenkins

echo "=======> [jenkins] installing jenkins components :"
kubectl apply -f jenkins/jenkins-pv.yaml
kubectl apply -f jenkins/jenkins-pvc.yaml
kubectl apply -f jenkins/jenkins-deployment.yaml
kubectl apply -f jenkins/jenkins-clusterip.yaml
kubectl apply -f jenkins/jenkins-ingress.yaml

echo "=======> [jenkins] waiting for jenkins' pod to run :"
while [[ -z "`kubectl get pods | grep jenkins | grep Running`" ]]; do sleep 5; done

echo "=======> [jenkins] printing jenkins' admin password :"
kubectl cp $( kubectl get pods | grep jenkins | tr -s ' ' | cut -d ' ' -f1 ):/var/jenkins_home/secrets/initialAdminPassword ./jenkinsInitialAdminPassword
cat jenkinsInitialAdminPassword
rm jenkinsInitialAdminPassword

echo "=======> DONE"
