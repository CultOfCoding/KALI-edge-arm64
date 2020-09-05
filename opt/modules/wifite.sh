#!/bin/bash

#WIFITE - автоматический взлом wifi
cp /usr/share/dict/wordlist-probable.txt /tmp/dict
chattr -i /usr/share/dict/wordlist-probable.txt

cd /tmp
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install libpcap-dev libcurl4-openssl-dev libpcap-dev wifite aircrack-ng
git clone https://github.com/JPaulMora/Pyrit.git
cd Pyrit
python setup.py install
cd ..
rm -r Pyrit

git clone https://github.com/ZerBea/hcxdumptool
cd hcxdumptool
make && make install
cd ..
rm -r hcxdumptool

git clone https://github.com/ZerBea/hcxtools
cd hcxtools
make && make install
cd ..
rm -r hcxtools

git clone https://github.com/hashcat/hashcat.git
cd hashcat
make && make install
cd ..
rm -r hashcat

git clone https://github.com/aanarchyy/bully
cd bully*/
cd src/
make && sudo make install
cd ../..
rm -r bully

apt-get -y --fix-broken install

echo '#!/bin/bash
ifconfig
echo ""
read -p "Введите название интерфейса: " name
setmon $name
sudo -u root wifite'>/usr/bin/wifite2
chmod +x /usr/bin/wifite2

#AIRGEDDON полуавтоматический
cd /opt
git clone https://github.com/v1s1t0r1sh3r3/airgeddon.git
cd airgeddon
printf "\n\n\n\n\n1\n0\n" | ./airgeddon.sh -i

mv /tmp/dict /usr/share/dict/wordlist-probable.txt

modules
