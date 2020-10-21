#!/bin/bash
#
# https://github.com/Nyr/openvpn-install
#
# Copyright (c) 2013 Nyr. Released under the MIT License.


# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
	echo 'This installer needs to be run with "bash", not "sh".'
	exit
fi

# Discard stdin. Needed when running from an one-liner which includes a newline
read -N 999999 -t 0.001

# Detect OpenVZ 6
if [[ $(uname -r | cut -d "." -f 1) -eq 2 ]]; then
	echo "The system is running an old kernel, which is incompatible with this installer."
	exit
fi

# Detect OS
# $os_version variables aren't always in use, but are kept here for convenience
if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
elif [[ -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -oE '[0-9]+' /etc/centos-release | head -1)
	group_name="nobody"
elif [[ -e /etc/fedora-release ]]; then
	os="fedora"
	os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
	group_name="nobody"
else
	echo "This installer seems to be running on an unsupported distribution.
Supported distributions are Ubuntu, Debian, CentOS, and Fedora."
	exit
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
	echo "Ubuntu 18.04 or higher is required to use this installer.
This version of Ubuntu is too old and unsupported."
	exit
fi

if [[ "$os" == "debian" && "$os_version" -lt 9 ]]; then
	echo "Debian 9 or higher is required to use this installer.
This version of Debian is too old and unsupported."
	exit
fi

if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
	echo "CentOS 7 or higher is required to use this installer.
This version of CentOS is too old and unsupported."
	exit
fi

# Detect environments where $PATH does not include the sbin directories
if ! grep -q sbin <<< "$PATH"; then
	echo '$PATH does not include sbin. Try using "su -" instead of "su".'
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit
fi

if [[ ! -e /dev/net/tun ]] || ! ( exec 7<>/dev/net/tun ) 2>/dev/null; then
	echo "The system does not have the TUN device available.
TUN needs to be enabled before running this installer."
	exit
fi

new_client () {
	# Generates the custom client.ovpn
	{
	cat /etc/openvpn/server/client-common.txt
	echo "<ca>"
	cat /etc/openvpn/server/easy-rsa/pki/ca.crt
	echo "</ca>"
	echo "<cert>"
	sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/server/easy-rsa/pki/issued/"$client".crt
	echo "</cert>"
	echo "<key>"
	cat /etc/openvpn/server/easy-rsa/pki/private/"$client".key
	echo "</key>"
	echo "<tls-crypt>"
	sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key
	echo "</tls-crypt>"
	} > ~/"$client".ovpn
}

if [[ ! -e /etc/openvpn/server/server.conf ]]; then
#	clear
	echo "OpenVPN is not installed."
else
	#clear
	echo "Revoking an existing client"
    # This option could be documented a bit better and maybe even be simplified
    # ...but what can I say, I want some sleep too
    number_of_clients=$(tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt | grep -c "^V")
    if [[ "$number_of_clients" = 0 ]]; then
        echo
        echo "There are no existing clients!"
        exit
    fi
    echo
    echo "Select the client to revoke:"
    tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
    read -p "Client: " client_number
    until [[ "$client_number" =~ ^[0-9]+$ && "$client_number" -le "$number_of_clients" ]]; do
        echo "$client_number: invalid selection."
        read -p "Client: " client_number
    done
    client=$(tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$client_number"p)
    echo
    read -p "Confirm $client revocation? [y/N]: " revoke
    until [[ "$revoke" =~ ^[yYnN]*$ ]]; do
        echo "$revoke: invalid selection."
        read -p "Confirm $client revocation? [y/N]: " revoke
    done
    if [[ "$revoke" =~ ^[yY]$ ]]; then
        cd /etc/openvpn/server/easy-rsa/
        ./easyrsa --batch revoke "$client"
        EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
        rm -f /etc/openvpn/server/crl.pem
        cp /etc/openvpn/server/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
        # CRL is read with each client connection, when OpenVPN is dropped to nobody
        chown nobody:"$group_name" /etc/openvpn/server/crl.pem
        echo
        echo "$client revoked!"
    else
        echo
        echo "$client revocation aborted!"
    fi
fi
