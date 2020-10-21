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

if [[ ! -z "$(virsh list --all | grep worker_node1 )" ]]
then
    cd run/worker
    vagrant destroy
    cd ../..
fi

rm -r run
