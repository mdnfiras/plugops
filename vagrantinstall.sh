apt update
apt -y install qemu-kvm libvirt-bin ebtables dnsmasq-base libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev vagrant
vagrant plugin install vagrant-libvirt
vagrant up --provider libvirt