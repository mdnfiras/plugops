#!/bin/bash

apt update
apt install -y resolvconf
echo "=======> setting up dns :"
systemctl start resolvconf.service
systemctl enable resolvconf.service
echo "nameserver 192.168.5.3" >> /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf.service

chmod u=x ovpn-ops/openvpn-install.sh
./ovpn-ops/openvpn-install.sh
