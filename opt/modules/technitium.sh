#!/bin/bash

chattr -i /etc/resolv.conf
echo 'nameserver 1.0.0.1'>/etc/resolv.conf
dnscrypt-proxy -service stop
dnscrypt-proxy -service uninstall

wget -q https://packages.microsoft.com/config/ubuntu/19.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get -y install apt-transport-https
sudo apt-get update
sudo apt-get -y install dotnet-runtime-3.1

wget https://download.technitium.com/dns/DnsServerPortable.tar.gz
sudo mkdir -p /etc/dns/
sudo tar -zxf DnsServerPortable.tar.gz -C /etc/dns/
rm DnsServerPortable.tar.gz
sudo cp /etc/dns/systemd.service /etc/systemd/system/dns.service
sudo systemctl enable dns.service
sudo systemctl start dns.service

echo 'nameserver 127.0.0.1'>/etc/resolv.conf
chattr +i /etc/resolv.conf
modules
