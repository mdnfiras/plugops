# Automatic deployment of a DevOps test environment

Automatic deployment of a customized, containerized DevOps environment for testing applications.

- Infrastructure provisioning on cloud & on premise.

- Networks services management (DNS, NFS, VPN...).

- DevSecOps toolchain deployment.

- Monitoring, logging and visualizing.

- Installation and management user interfaces (UI).



Deployment example:
<img src='readme/deployment.png' style="display:inline-block">

# Installation

Clone the repository.

```bash
git clone https://github.com/mdnfiras/k8s-devops-env.git
```

Change directory.

```bash
cd k8s-devops-env
```

Install Vagrant on the host server along with all the required packages and plugins (KVM & LibVirt).


```bash
sudo chmod u=x requirements.sh
sudo ./requirements.sh
```

# Usage

Documentation ongoing !