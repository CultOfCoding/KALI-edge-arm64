#!/bin/bash

export PATH=/sbin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
export DEBIAN_FRONTEND=noninteractive

clear
printf 'r@@t31337\nr@@t31337' | passwd root

chattr -i /etc/resolv.conf
echo 'nameserver 1.0.0.1' | tee /etc/resolv.conf

hostt=$(cat /etc/hostname)
sed -i "s+localhost+localhost $hostt+g" /etc/hosts

echo 'deb http://deb.debian.org/debian buster main contrib non-free'>/etc/apt/sources.list
apt-get update
apt-get -y dist-upgrade
apt-get -y --fix-broken install
printf "no\nno" | DEBIAN_FRONTEND=noninteractive apt-get -y install iptables-persistent 
apt-get -y install net-tools nmap p0f torsocks python-setuptools python3-setuptools jq resolvconf software-properties-common qrencode cockpit tor sudo zsh-syntax-highlighting curl python-dev git python3-dev python3-pip python3-setuptools fzf 
systemctl enable tor
systemctl start tor
sleep 5
apt-get -y --fix-broken install

rm /etc/tor/torsocks.conf
echo 'TorAddress 127.0.0.1'>/etc/tor/torsocks.conf
echo 'TorPort 137'>>/etc/tor/torsocks.conf
echo 'OnionAddrRange 127.42.42.0/24'>>/etc/tor/torsocks.conf
rm /etc/tor/torrc
echo 'SocksPort 137'>/etc/tor/torrc
echo 'RunAsDaemon 1'>>/etc/tor/torrc
systemctl restart tor

sleep 3

torsocks git clone https://github.com/jotyGill/quickz-sh.git
cd quickz-sh
torsocks ./quickz.sh
usermod --shell /bin/zsh root

#osfooler
wget http://ftp.br.debian.org/debian/pool/main/n/nfqueue-bindings/python-nfqueue_0.6-1+b3_arm64.deb
dpkg -i python-nfqueue_0.6-1+b1_arm64.deb && rm python-nfqueue_0.6-1+b1_arm64.deb
apt-get -y --fix-broken install
apt-get -y install libnetfilter-queue-dev arptables libnetfilter-queue1 libnetfilter-acct1 libnetfilter-conntrack3 nftables
apt-get -y --fix-broken install
torsocks git clone https://github.com/kti/python-netfilterqueue.git
cd python-netfilterqueue
python setup.py install
cd ..
rm -r python-netfilterqueue

torsocks git clone https://github.com/moonbaseDelta/OSfooler-ng.git
cd OSfooler-ng
python setup.py install
cd ..
rm -r OSfooler-ng

osfooler-ng -u

iface=$(ip route get 1.1.1.1 | grep -Po '(?<=dev\s)\w+' | cut -f1 -d ' ')

cat <<EOF>fooler
#!/bin/bash
osfooler-ng -m "Microsoft Windows 2000 SP4" -o "Windows" -d "2000 SP4" -i $iface &
EOF

chmod +x fooler
mv fooler /usr/bin/
