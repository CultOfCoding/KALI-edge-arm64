#!/bin/bash

#freedownloaadmanager 
cd /opt
wget https://dn3.freedownloadmanager.org/6/latest/freedownloadmanager.deb 
dpkg -i /opt/freedownloadmanager.deb 
apt-get -y --fix-broken install 

echo 'alias fdm="screen sudo -u x /opt/freedownloadmanager/fdm"' >> /root/.zshrc
