#!/bin/bash

echo "=======> updating and upgrading :"

apt update
apt upgrade -y

echo "=======> installing DNS packages :"

apt install -y bind9 dnsutils

echo "=======> configuring NameServer :"

cat /etc/bind/named.conf.options | head -12 > /etc/bind/named.conf.options.temp
printf %"s\n" \
"   forwarders {" \
"       8.8.8.8;" \
"       8.8.4.4;" \
"       1.1.1.1;" \
"   };" >> /etc/bind/named.conf.options.temp
cat /etc/bind/named.conf.options | tail -11 >> /etc/bind/named.conf.options.temp
rm /etc/bind/named.conf.options
mv /etc/bind/named.conf.options.temp /etc/bind/named.conf.options
cat /etc/bind/named.conf.options
systemctl restart bind9

echo "=======> primary master, forward zone file :"

printf %"s\n" \
"zone \"[[DOMAIN]]\" {" \
"   type master;" \
"   file \"/etc/bind/db.[[DOMAIN]]\";" \
"};" >> /etc/bind/named.conf.local
cat /etc/bind/named.conf.local

printf %"s\n" \
";" \
"; BIND data file for [[DOMAIN]]" \
";" > /etc/bind/db.[[DOMAIN]]
cat /etc/bind/db.local | head -4 | tail -1 >> /etc/bind/db.[[DOMAIN]]
cat /etc/bind/db.local | grep root.localhost | sed -e 's/root.localhost./root.[[DOMAIN]]./g' | sed -e 's/localhost./[[DOMAIN]]./g' >> /etc/bind/db.[[DOMAIN]]
cat /etc/bind/db.local | head -10 | tail -5 >> /etc/bind/db.[[DOMAIN]]
cat /etc/bind/db.local | grep NS | sed -e 's/localhost./ns.[[DOMAIN]]./g' >> /etc/bind/db.[[DOMAIN]]
echo -e "ns\tIN\tA\t192.168.5.3" >> /etc/bind/db.[[DOMAIN]]
echo -e "; your sites" >> /etc/bind/db.[[DOMAIN]]
echo -e "*.devops\tIN\tA\t192.168.5.100" >> /etc/bind/db.[[DOMAIN]]
echo -e "devops\tIN\tA\t192.168.5.10" >> /etc/bind/db.[[DOMAIN]]
echo -e "nfs\tIN\tA\t192.168.5.5" >> /etc/bind/db.[[DOMAIN]]
echo -e "vpn\tIN\tA\t192.168.5.7" >> /etc/bind/db.[[DOMAIN]]
systemctl restart bind9

echo "=======> primary master, reverse zone file :"

printf %"s\n" \
"" \
"zone \"5.168.192.in-addr.arpa\" {" \
"   type master;" \
"   file \"/etc/bind/db.192\";" \
"};" >> /etc/bind/named.conf.local
cat /etc/bind/named.conf.local

printf %"s\n" \
";" \
"; BIND reverse data file for local 192.168.5.X net" \
";" > /etc/bind/db.192
cat /etc/bind/db.127 | head -4 | tail -1 >> /etc/bind/db.192
cat /etc/bind/db.127 | grep root.localhost | sed -e 's/root.localhost./root.[[DOMAIN]]./g' | sed -e 's/localhost./[[DOMAIN]]./g' >> /etc/bind/db.192
cat /etc/bind/db.127 | head -11 | tail -6 >> /etc/bind/db.192
cat /etc/bind/db.127 | grep NS | sed -e 's/localhost./ns./g' >> /etc/bind/db.192
echo -e "3\tIN\tPTR\tns.[[DOMAIN]]." >> /etc/bind/db.192
echo -e "100\tIN\tPTR\t*.devops.[[DOMAIN]]." >> /etc/bind/db.192
echo -e "10\tIN\tPTR\tdevops.[[DOMAIN]]." >> /etc/bind/db.192
echo -e "5\tIN\tPTR\tnfs.[[DOMAIN]]." >> /etc/bind/db.192
echo -e "7\tIN\tPTR\tvpn.[[DOMAIN]]." >> /etc/bind/db.192
cat /etc/bind/db.192
systemctl restart bind9

echo "=======> setting up dns :"

apt install -y resolvconf
systemctl start resolvconf.service
systemctl enable resolvconf.service
echo "nameserver 192.168.5.3" >> /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf.service
