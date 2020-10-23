#!/bin/bash

if [[ ! $(whoami) = "root" ]]
then
    echo "Usage: Must be root"
    exit 1
fi

if [[ ! -z "$(virsh list --state-shutoff | grep dns_dns )" ]]
then
    cd run/dns
    vagrant up
    cd ../..
fi

if [[ ! -z "$(virsh list --state-shutoff | grep nfs_nfs )" ]]
then
    cd run/nfs
    vagrant up
    cd ../..
fi

if [[ ! -z "$(virsh list --state-shutoff | grep vpn_vpn )" ]]
then
    cd run/vpn
    vagrant up
    cd ../..
fi

if [[ ! -z "$(virsh list --state-shutoff | grep main_main )" ]]
then
    cd run/main
    vagrant up
    cd ../..
fi

while [[ ! -z "$(virsh list --state-shutoff | grep worker )" ]]
do
    WORKER=$(virsh list --state-shutoff | grep worker | tr -s ' ' | cut -d ' ' -f3 | cut -d_ -f1 )
    cd run/$WORKER
    vagrant up
    cd ../..
done

