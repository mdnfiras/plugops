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

if [ -d run ]
then
    ./cleanup.sh
fi
mkdir run
cp -r dns run/dns
cp -r nfs run/nfs
cp -r vpn run/vpn
cp -r main run/main
cp -r worker run/worker
sed -i "s/\[\[DOMAIN\]\]/$DOMAIN/g" run/dns/initscripts/dnsinstall.sh
sed -i "s/\[\[DOMAIN\]\]/$DOMAIN/g" run/worker/initscripts/workerkubeinstall.sh
sed -i "s/\[\[DOMAIN\]\]/$DOMAIN/g" run/main/initscripts/mainkubeinstall.sh
sed -i "s/\[\[DOMAIN\]\]/$DOMAIN/g" run/main/jenkins/jenkins-ingress.yaml
sed -i "s/\[\[DOMAIN\]\]/$DOMAIN/g" run/main/jenkins/jenkins-pv.yaml
sed -i "s/\[\[DOMAIN\]\]/$DOMAIN/g" run/main/tls/myapp-ingress-tls.yaml
cd run

cd dns
vagrant up --provider libvirt | tee dns.logs

echo "=======> testing the DNS server :"
tries=0
while [[ ! -z "$(nslookup ns.$DOMAIN 192.168.5.3 | grep NXDOMAIN )" ]]
do
    tries=$(( $tries + 1 ))
    if [[ $tries -eq 2 ]]
    then
        echo "=======> DNS server not working"
        break
    fi
    sleep 5
done

cd ../nfs
vagrant up --provider libvirt | tee nfs.logs

echo "=======> waiting for NFS server to be ready :"
curl 192.168.5.5:2049
if [[ ! $? -eq 52 ]]
then
    echo "=======> NFS server not working"
fi

cd ../vpn
vagrant up --provider libvirt | tee vpn.logs

echo "=======> waiting for NFS server to be ready :"
curl 192.168.5.7:1194
if [[ ! $? -eq 52 ]]
then
    echo "=======> NFS server not working";
fi

cd ../worker
vagrant up --provider libvirt > logs &
cd ../main
vagrant up --provider libvirt > logs &
