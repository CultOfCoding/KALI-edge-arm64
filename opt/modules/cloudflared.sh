#!/bin/bash

cd /opt
wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-arm64.deb
dpkg -i cloudflared-stable-linux-arm64.deb
rm cloudflared-stable-linux-arm64.deb

/etc/dnscrypt-proxy/dnscrypt-proxy -service stop
/etc/dnscrypt-proxy/dnscrypt-proxy -service uninstall

mkdir -p /usr/local/etc/cloudflared
/usr/bin/cat << EOF > /usr/local/etc/cloudflared/config.yml
proxy-dns: true
proxy-dns-upstream:
 - https://1.1.1.1/dns-query
 - https://1.0.0.1/dns-query
EOF

cloudflared service install
cp /etc/cloudflared/cert.pem /usr/local/etc/cloudflared/
cloudflared service install
cloudflared &

chattr -i /etc/resolv.conf
rm /etc/resolv.conf
echo 'nameserver 127.0.0.1'>/etc/resolv.conf
chattr +i /etc/resolv.conf
modules
