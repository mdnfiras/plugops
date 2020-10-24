#!/bin/bash

named-checkzone [[DOMAIN]] /etc/bind/db.[[DOMAIN]]
named-checkzone 5.168.192.in-addr.arpa. /etc/bind/db.192
named-checkconf  /etc/bind/named.conf.local
named-checkconf  /etc/bind/named.conf

nslookup ns.[[DOMAIN]]
nslookup nfs.[[DOMAIN]]
nslookup vpn.[[DOMAIN]]
nslookup devops.[[DOMAIN]]
nslookup jenkins.devops.[[DOMAIN]]
