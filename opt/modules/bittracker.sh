#!/bin/bash

apt-get -y install apache2
systemctl enable apache2
systemctl start apache2
wget https://github.com/x4ck/me/raw/master/bittracker.tar -O /opt/modules/bittracker.tar
tar xf /opt/modules/bittracker.tar -C /var/www/html/
chown -hR www-data /var/www/html
mv /var/www/html/BitTracker.desktop /home/x/Desktop/
modules
