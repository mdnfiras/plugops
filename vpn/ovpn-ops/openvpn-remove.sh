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
	echo "Removing OpenVPN"
	echo
    read -p "Confirm OpenVPN removal? [y/N]: " remove
    until [[ "$remove" =~ ^[yYnN]*$ ]]; do
        echo "$remove: invalid selection."
        read -p "Confirm OpenVPN removal? [y/N]: " remove
    done
    if [[ "$remove" =~ ^[yY]$ ]]; then
        port=$(grep '^port ' /etc/openvpn/server/server.conf | cut -d " " -f 2)
        protocol=$(grep '^proto ' /etc/openvpn/server/server.conf | cut -d " " -f 2)
        if systemctl is-active --quiet firewalld.service; then
            ip=$(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING | grep '\-s 10.8.0.0/24 '"'"'!'"'"' -d 10.8.0.0/24' | grep -oE '[^ ]+$')
            # Using both permanent and not permanent rules to avoid a firewalld reload.
            firewall-cmd --remove-port="$port"/"$protocol"
            firewall-cmd --zone=trusted --remove-source=10.8.0.0/24
            firewall-cmd --permanent --remove-port="$port"/"$protocol"
            firewall-cmd --permanent --zone=trusted --remove-source=10.8.0.0/24
            firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to "$ip"
            firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to "$ip"
            if grep -qs "server-ipv6" /etc/openvpn/server/server.conf; then
                ip6=$(firewall-cmd --direct --get-rules ipv6 nat POSTROUTING | grep '\-s fddd:1194:1194:1194::/64 '"'"'!'"'"' -d fddd:1194:1194:1194::/64' | grep -oE '[^ ]+$')
                firewall-cmd --zone=trusted --remove-source=fddd:1194:1194:1194::/64
                firewall-cmd --permanent --zone=trusted --remove-source=fddd:1194:1194:1194::/64
                firewall-cmd --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
                firewall-cmd --permanent --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
            fi
        else
            systemctl disable --now openvpn-iptables.service
            rm -f /etc/systemd/system/openvpn-iptables.service
        fi
        if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" && [[ "$port" != 1194 ]]; then
            semanage port -d -t openvpn_port_t -p "$protocol" "$port"
        fi
        systemctl disable --now openvpn-server@server.service
        rm -rf /etc/openvpn/server
        rm -f /etc/systemd/system/openvpn-server@server.service.d/disable-limitnproc.conf
        rm -f /etc/sysctl.d/30-openvpn-forward.conf
        if [[ "$os" = "debian" || "$os" = "ubuntu" ]]; then
            apt-get remove --purge -y openvpn
        else
            # Else, OS must be CentOS or Fedora
            yum remove -y openvpn
        fi
        echo
        echo "OpenVPN removed!"
    else
        echo
        echo "OpenVPN removal aborted!"
    fi
fi
