#!/bin/bash

apt-get update
apt-get -y install tigervnc-scraping-server
mkdir /home/x/.vnc
mv passwd /home/x/.vnc/
chown -hR x /home/x/.vnc
mv startvnc /usr/bin/
mv vnclocal.desktop /home/x/.config/autostart/
sudo -u x sudo chmod +x /home/x/.config/autostart/vnclocal.desktop
sudo -u x sudo chmod +x /usr/bin/startvnc
DEBIAN_FRONTEND=noninteractive apt-get -y install ssh
mv sshd_config /etc/ssh/
printf "1234\n1234" | passwd root
systemctl enable ssh

startvnc start
