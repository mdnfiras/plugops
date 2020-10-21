#!/bin/bash

apt update
apt install -y resolvconf
echo "=======> setting up dns :"
systemctl start resolvconf.service
systemctl enable resolvconf.service
echo "nameserver 192.168.5.3" >> /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf.service

mkdir ovpn-ops
wget https://raw.githubusercontent.com/mdnfiras/k8s-devops-env/master/vpn/ovpn-ops/openvpn-install.sh -P ovpn-ops
wget https://raw.githubusercontent.com/mdnfiras/k8s-devops-env/master/vpn/ovpn-ops/openvpn-remove.sh -P ovpn-ops
wget https://raw.githubusercontent.com/mdnfiras/k8s-devops-env/master/vpn/ovpn-ops/client-add.sh -P ovpn-ops
wget https://raw.githubusercontent.com/mdnfiras/k8s-devops-env/master/vpn/ovpn-ops/client-remove.sh -P ovpn-ops

chmod u=x ovpn-ops/openvpn-install.sh
./ovpn-ops/openvpn-install.sh
