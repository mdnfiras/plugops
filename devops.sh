#!/bin/bash

if [[ ! $(whoami) = "root" ]]
then
    echo "Usage: Must be root"
    exit 1
fi


while getopts ":d:n:" opt; do
  case $opt in
    d) DOMAIN=${OPTARG} ;;
    n) K8S_N=${OPTARG} ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

if [[ -z $DOMAIN ]]
then
    DOMAIN=example.com
    echo 'Assuming flag -d set to example.com'
fi

if [[ -z $K8S_N ]]
then
    K8S_N=1
    echo 'Assuming flag -n set to 1'
fi

echo "domain: $DOMAIN"
echo "worker nodes: $K8S_N"

if [ ! -d run ]
then
    flags="-d $DOMAIN -n $K8S_N"
    chmod u=rwx create-run.sh
    ./create-run.sh $flags
fi

cd run

echo "Running DNS server..."
cd dns
vagrant up --provider libvirt > dns.logs
cd ..

echo "Running NFS server..."
cd nfs
vagrant up --provider libvirt > nfs.logs
cd ..

# echo "Running VPN server..."
# cd vpn
# vagrant up --provider libvirt > vpn.logs
# cd ..

for (( i=1; i<=$K8S_N; i++ ))
do
  echo "Running k8s worker$i..."
  cd worker$i
  vagrant up --provider libvirt > worker$i.logs &
  cd ..
done

echo "Running k8s main..."
cd main
vagrant up --provider libvirt > main.logs
cd ..

chmod u=rwx test.sh
./test.sh $DOMAIN
