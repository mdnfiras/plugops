# Automated DevOps environment deployment

Automated deployment of a DevOps environment on a k8s cluster provisioned by Vagrant on a Ubuntu Server 18.04

# Installation

Clone the repository.

```bash
git clone https://github.com/mdnfiras/devops-infra.git
```

Change directory.

```bash
cd ovpn
```

Install Vagrant on the host server along with all the required packages and plugins (KVM & LibVirt).


```bash
sudo chmod u=x vagrantinstall.sh
sudo ./vagrantinstall.sh
```

# Usage

Start the Vagrant ovpn virtual machine, provision it to install k8s on all the nodes, k8s control plane on the main node, join nodes, deploy Jenkins along with a NodePort service that will expose Jenkins' web interface on <any_node_ip>:30001

```bash
sudo vagrant up --provider libvirt
```

You can use any node IP (Vagrant's default network or the private network defined in the Vagrantfile, i.e 192.168.5.10)

# Removal

Run the following commands in the project's directory:

```bash
sudo vagrant destroy main
sudo vagrant destroy node1
sudo vagrant destroy node2
```
