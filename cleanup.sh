#!/bin/bash

if [[ ! $(whoami) = "root" ]]
then
    echo "Usage: Must be root"
    exit 1
fi

if [[ ! -z "$(virsh list --all | grep dns_dns )" ]]
then
    cd run/dns
    vagrant destroy
    cd ../..
fi

if [[ ! -z "$(virsh list --all | grep nfs_nfs )" ]]
then
    cd run/nfs
    vagrant destroy
    cd ../..
fi

if [[ ! -z "$(virsh list --all | grep vpn_vpn )" ]]
then
    cd run/vpn
    vagrant destroy
    cd ../..
fi

if [[ ! -z "$(virsh list --all | grep main_main )" ]]
then
    cd run/main
    vagrant destroy
    cd ../..
fi

while [[ ! -z "$(virsh list --all | grep worker )" ]]
do
    WORKER=$(virsh list --all | grep worker | tr -s ' ' | cut -d ' ' -f3 | cut -d_ -f1 )
    cd run/$WORKER
    vagrant destroy
    cd ../..
done

while true; do
    read -p "Do you wish to remove the run folder?" yn
    case $yn in
        [Yy]* ) rm -r run; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done


