#!/bin/bash

if [[ ! $(whoami) = "root" ]]
then
    echo "Usage: Must be root"
    exit 1
fi

if [ "$#" -ne 1 ]
then
    echo "Usage: Must supply a domain"
    exit 1
fi

DOMAIN=$1

echo "=======> testing the DNS server :"
tries=0
if [[ ! -z "$(nslookup ns.$DOMAIN 192.168.5.3 | grep NXDOMAIN )" ]]
then
    echo "=======> DNS server not working"
else
    echo "=======> DNS server working"
fi


echo "=======> testing the NFS server :"
curl 192.168.5.5:2049
if [[ ! $? -eq 52 ]]
then
    echo "=======> NFS server not working"
else
    echo "=======> NFS server working"
fi


echo "=======> testing the main node :"
res=$(curl http://$DOMAIN --resolve $DOMAIN:80:192.168.5.10 )
if [[ -z "$res" ]] | [[ ! $? -eq 0 ]]
then
    echo "=======> main node not working"
else
    echo "=======> main node working"
fi


echo "=======> testing the jenkins interface :"
res=$(curl http://jenkins.devops.$DOMAIN --resolve jenkins.devops.$DOMAIN:80:192.168.5.100 )
if [[ -z "$res" ]] | [[ ! $? -eq 0 ]]
then
    echo "=======> jenkins interface not working"
else
    echo "=======> jenkins interface working"
fi

