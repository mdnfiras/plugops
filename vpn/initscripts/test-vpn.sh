#!/bin/bash

ufw status

nslookup ns.[[DOMAIN]]
nslookup nfs.[[DOMAIN]]
nslookup vpn.[[DOMAIN]]
nslookup devops.[[DOMAIN]]
nslookup jenkins.devops.[[DOMAIN]]
