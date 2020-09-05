#!/bin/bash

clear
echo ""
export TERM=xterm-256color
USE_COLORS=true
echo 'PermitTTY yes'>>/etc/ssh/sshd_config
systemctl restart ssh


    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    PLAIN='\033[0m'

    RED_BOLD='\033[1;31m'
    GREEN_BOLD='\033[1;32m'
    BLUE_BOLD='\033[1;34m'
    YELLOW_BOLD='\033[1;33m'
    PLAIN_BOLD='\033[1;37m'

{
export PATH=/sbin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
export DEBIAN_FRONTEND=noninteractive

chattr -i /etc/resolv.conf
echo 'nameserver 1.0.0.1' | tee /etc/resolv.conf

hostt=$(cat /etc/hostname)
sed -i "s+localhost+localhost $hostt+g" /etc/hosts

echo 'deb http://deb.debian.org/debian buster main contrib non-free'>/etc/apt/sources.list
}&>/dev/null

apt-get update
echo ""
printf "${YELLOW}Установка началась, время установки ${GREEN_BOLD}не более 15 минут${PLAIN}\n"

{
apt-get -y dist-upgrade
apt-get -y --fix-broken install
apt-get -y install net-tools e2fsprogs python3-pip python3-dev sudo unbound -qq
apt-get -y purge exim4 exim4-daemon-light
pip3 install pproxy python-daemon asyncio

systemctl unmask systemd-resolved
systemctl disable systemd-resolved
systemctl stop systemd-resolved

#unbound
echo 'interface: 127.0.0.1
hide-identity: yes
hide-version: yes
use-caps-for-id: yes
prefetch: yes' >> /etc/unbound/unbound.conf

if pgrep systemd-journal; then
   systemctl enable unbound
   systemctl restart unbound
else
   service unbound restart
fi

#echo '#!/bin/bash
#sleep 3
#pproxy -l http+socks4+socks5://:55454/ --daemon'>/etc/network/if-up.d/pproxy
#chmod +x /etc/network/if-up.d/pproxy

cat <<EOF>/etc/systemd/system/pproxy.service
[Unit]
Description=pproxy
After=network.target

[Service]
Type=simple
ExecStart=pproxy -l http+socks4+socks5://:55454/ --daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
chmod +x /etc/systemd/system/pproxy.service
systemctl start pproxy
systemctl enable pproxy

cat <<EOF>sysctl.conf
net.ipv4.ip_default_ttl = 128
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv6.icmp_echo_ignore_all = 1
net.ipv6.icmp_ignore_bogus_error_responses = 1
net.ipv6.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_window_scaling = 0
EOF
mv sysctl.conf /etc/

echo 'nameserver 127.0.0.1' | tee /etc/resolv.conf
chattr +i /etc/resolv.conf

systemctl disable ssh
systemctl disable sshd
}&>/dev/null

reboot
