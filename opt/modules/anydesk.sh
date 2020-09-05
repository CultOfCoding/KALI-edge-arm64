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

apt -y install flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.anydesk.Anydesk
flatpak run com.anydesk.Anydesk
cat<<EOF>/usr/share/applications/anydesk.desktop
[Desktop Entry]
Name=Anydesk
GenericName=123
Exec=flatpak run com.anydesk.Anydesk
Icon=anydesk
Terminal=false
Type=Application
EOF

printf "${YELLOW}..Для возврата в меню модулей нажмите ${RED_BOLD}[Enter]${PLAIN}"
read -p " " mmm
modules

