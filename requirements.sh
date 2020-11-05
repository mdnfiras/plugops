apt update
apt -y install qemu-kvm libvirt-bin ebtables dnsmasq-base libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev vagrant software-properties-common
vagrant plugin install vagrant-libvirt
apt-add-repository --yes --update ppa:ansible/ansible
apt -y install ansible
ansible-galaxy collection install community.general
