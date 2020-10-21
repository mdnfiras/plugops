#!/bin/bash

apt update
apt install -y nfs-common nfs-kernel-server resolvconf

echo "=======> setting up dns :"
systemctl start resolvconf.service
systemctl enable resolvconf.service
echo "nameserver 192.168.5.3" >> /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf.service

mkdir -p /mnt/nfs_share
chown -R nobody:nogroup /mnt/nfs_share

echo "/mnt/nfs_share    192.168.5.0/24(rw,sync,no_subtree_check)" >> /etc/exports
exportfs -a
systemctl restart nfs-kernel-server

printf "y\n" | ufw enable
ufw status
ufw allow from 192.168.5.0/24 to any port nfs
ufw allow from 192.168.121.0/24 to any port ssh
ufw reload
ufw status

