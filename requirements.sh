apt update
apt -y install qemu-kvm libvirt-bin ebtables dnsmasq-base libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev software-properties-common
wget https://releases.hashicorp.com/vagrant/2.2.10/vagrant_2.2.10_x86_64.deb
dpkg -i vagrant_2.2.10_x86_64.deb
vagrant plugin install vagrant-libvirt
apt-add-repository --yes --update ppa:ansible/ansible
apt -y install ansible
ansible-galaxy collection install community.general
