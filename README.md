# devops-infra

Automatic deployment of a DevOps environment on a k8s cluster provisioned by Vagrant on a Ubuntu Server 18.04

Run the script vagrantinstall.sh to install Vagrant on the host server along with all the required packages and plugins (KVM & LibVirt)
The script will proceed to launching the virtual machines, provisionning them by installing k8s and Calico networking solution, joining the worker nodes to the master nodes automatically, and finally installing Jenkins and exposing its web interface on 192.168.5.10:30001
