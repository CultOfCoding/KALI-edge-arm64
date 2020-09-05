#!/bin/bash

cp -r etc/* /etc/
cp -r usr/* /usr/

printf "y\nwlan1" | hashcatch --setup

ls /sys/class/net/wlan*/wireless | cut -d"/" -f 5 > /tmp/w
mon=$(cat /tmp/w | grep -v $(echo /sys/class/net/wlan*/wireless | awk -F'/' '{ print $5 }'))
printf "$mon" | sed '1d' > /tmp/i

echo interface=$(echo $(cat /tmp/i)) > etc/hashcatch/hashcatch.conf

nmcli dev wifi > /tmp/w
echo ignore="$(cat /tmp/w | grep '*' | cut -d" " -f 10)" >> etc/hashcatch/hashcatch.conf
cp -r etc/* /etc/
cp -r usr/* /usr/

echo 'alias x4k-db="cat /usr/share/hashcatch/db"' >> /root/.zshrc
. /root/.zshrc
cd

screen -S hc hashcatch

