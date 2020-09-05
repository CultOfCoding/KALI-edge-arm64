#!/bin/bash

cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo 'deb http://archive-4.kali.org/kali kali-rolling main non-free contrib'>>/etc/apt/sources.list
wget http://http.kali.org/pool/main/k/kali-archive-keyring/kali-archive-keyring_2020.2_all.deb && dpkg -i kali-archive-keyring_2020.2_all.deb && rm kali*
apt update

apt-get -y install docker.io docker-compose
systemctl enable docker
systemctl start docker

mv /etc/apt/sources.list.bak /etc/apt/sources.list
apt update

docker run -d -p 5566:5566 -p 4444:4444 --env tors=25 mattes/rotating-proxy

echo '#!/bin/bash
sleep 3
echo $(docker container ls --all | grep mattes | cut -d' ' -f1 | sed -e 's+CONTAINER++g') | xargs -L 1 docker container rm --force
docker run -d -p 5566:5566 -p 4444:4444 --env tors=25 mattes/rotating-proxy'>/etc/network/if-up.d/powerproxy && chmod +x /etc/network/if-up.d/powerproxy

#glider
LATEST_URL="https://api.github.com/repos/nadoo/glider/releases"
rmersion=$(curl -sL "$rmersion" | grep "tag_name" | head -1 | cut -d \" -f 4)
workdir="/tmp/glider"
mkdir /tmp/glider && cd /tmp/glider
wget -nv --show-progress $(curl -sL "$rmersion" | grep linux_arm64.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4)
tar xf * && rm *.tar.gz
mv */glider /usr/bin/
rm -r glider*

echo 'glider -listen $1:$2@:5567 -forward http://:5566 -verbose'>/usr/bin/cproxy
chmod +x /usr/bin/cproxy
