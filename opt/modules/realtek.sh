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

#cd /tmp
#apt-get -y purge firmware-realtek
#git clone https://github.com/aircrack-ng/rtl8812au
#cd rtl8812au
#apt-get -y install bc
#./dkms-install.sh
#rm -r ../rtl8812au

cd /tmp
git clone https://github.com/Mange/rtl8192eu-linux-driver
cd rtl8192eu-linux-driver
dkms add .
dkms autoinstall
echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
echo -e "8192eu\n\nloop" | sudo tee /etc/modules
echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
sudo update-grub
sudo update-initramfs -u

printf "${YELLOW}..Для возврата в меню модулей нажмите ${RED_BOLD}[Enter]${PLAIN}"
read -p " " mmm
modules

