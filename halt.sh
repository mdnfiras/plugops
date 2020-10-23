#!/bin/bash

if [[ ! $(whoami) = "root" ]]
then
    echo "Usage: Must be root"
    exit 1
fi

if [[ ! -z "$(virsh list --state-running | grep dns_dns )" ]]
then
    cd run/dns
    vagrant halt
    cd ../..
fi

if [[ ! -z "$(virsh list --state-running | grep nfs_nfs )" ]]
then
    cd run/nfs
    vagrant halt
    cd ../..
fi

if [[ ! -z "$(virsh list --state-running | grep vpn_vpn )" ]]
then
    cd run/vpn
    vagrant halt
    cd ../..
fi

if [[ ! -z "$(virsh list --state-running | grep main_main )" ]]
then
    cd run/main
    vagrant halt
    cd ../..
fi

while [[ ! -z "$(virsh list --state-running | grep worker )" ]]
do
    WORKER=$(virsh list --state-running | grep worker | tr -s ' ' | cut -d ' ' -f3 | cut -d_ -f1 )
    cd run/$WORKER
    vagrant halt
    cd ../..
done

