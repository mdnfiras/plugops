#!/bin/bash

named-checkzone [[DOMAIN]] /etc/bind/db.[[DOMAIN]]
named-checkzone 5.168.192.in-addr.arpa. /etc/bind/db.192
named-checkconf  /etc/bind/named.conf.local
named-checkconf  /etc/bind/named.conf

nslookup ns.[[DOMAIN]] 192.168.5.3
nslookup nfs.[[DOMAIN]] 192.168.5.3
nslookup vpn.[[DOMAIN]] 192.168.5.3
nslookup devops.[[DOMAIN]] 192.168.5.3
nslookup jenkins.devops.[[DOMAIN]] 192.168.5.3
