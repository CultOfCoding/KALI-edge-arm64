#!/bin/bash

export TERM=xterm-256color

USE_COLORS=true

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


#proxy2country
mkdir /opt/p2c
wget https://github.com/assnctr/unfx-proxy-to-country/releases/download/v1.0.0/unfx-proxy-to-country-v1.0.0-x64-linux.zip
unzip -o unfx-proxy-to-country-v1.0.0-x64-linux.zip -d /opt/p2c
rm unfx-proxy-to-country-v1.0.0-x64-linux.zip
chmod +x /opt/p2c/unfx-proxy-to-country
chown -hR x /opt/p2c

echo '[Desktop Entry]
Version=1.0
Name=proxy2country
Comment=great tool for work
Exec=/opt/p2c/unfx-proxy-to-country
Icon=map-globe
Terminal=false
Type=Application
Categories=
StartupNotify=true
OnlyShowIn=XFCE;
X-XfcePluggable=true
Path=/opt/p2c/'>/usr/share/applications/Proxy2Country.desktop

printf "${YELLOW}..Для возврата в меню модулей нажмите ${RED_BOLD}[Enter]${PLAIN}"
read -p " " mmm
modules

