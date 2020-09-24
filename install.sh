#!/bin/bash

export TERM=xterm-256color
export LC_ALL=en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

echo 'LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8' > /etc/default/locale

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

mv ../unkn0wn /root/
cd /root/unkn0wn
chmod +x usr/bin/*
mv usr/bin/spinner /usr/bin/
mv usr/bin/wait-online /usr/bin/
mv usr/bin/fanfix.sh /usr/bin/
fanfix.sh &

#@@
wait-online
#@@

#DNS-crypt
LATEST_URL="https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest"
INSTALL_DIR=/opt/dnscrypt-proxy
workdir=/tmp/dnscrypt
mkdir $workdir
wget $(curl -sL "$LATEST_URL" | grep dnscrypt-proxy-linux_arm64- | grep browser_download_url | head -1 | cut -d \" -f 4) && tar xf dnscrypt-proxy-linux_arm64-* -C $workdir
sudo chattr -i /etc/resolv.conf
sudo mkdir $INSTALL_DIR
sudo cp -r --preserve=all $workdir/linux-arm64/example-whitelist.txt $INSTALL_DIR/
sudo cp -r --preserve=all $workdir/linux-arm64/example-forwarding-rules.txt $INSTALL_DIR/
sudo cp -r --preserve=all $workdir/linux-arm64/example-cloaking-rules.txt $INSTALL_DIR/
sudo cp -r --preserve=all $workdir/linux-arm64/LICENSE $INSTALL_DIR/
sudo cp -r --preserve=all $workdir/linux-arm64/example-dnscrypt-proxy.toml $INSTALL_DIR/
sudo cp -r --preserve=all $workdir/linux-arm64/example-blacklist.txt $INSTALL_DIR/
sudo cp -r --preserve=all $workdir/linux-arm64/dnscrypt-proxy $INSTALL_DIR/
sudo cp -r --preserve=all $INSTALL_DIR/example-dnscrypt-proxy.toml $INSTALL_DIR/dnscrypt-proxy.toml
sudo sed -i "30c\server_names = [\'cloudflare\']" $INSTALL_DIR/dnscrypt-proxy.toml
sudo sed -i 's+127.0.0.1:53+127.0.0.1:5353+g' $INSTALL_DIR/dnscrypt-proxy.toml

sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
echo 'port=53
server=127.0.0.1#5353' > /etc/dnsmasq.conf
sudo rm -r /etc/resolv.conf
echo nameserver 127.0.0.1 > /tmp/resolv.conf
sudo cp -r /tmp/resolv.conf /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
sudo $INSTALL_DIR/dnscrypt-proxy -service install
sudo ln -s $INSTALL_DIR/dnscrypt-proxy /bin/
sudo systemctl enable dnscrypt-proxy
sudo $INSTALL_DIR/dnscrypt-proxy -service start
sudo rm -r $workdir /tmp/resolv.conf
sudo sed -i 's+cache_size = 4096+cache_size = 256000+g' /opt/dnscrypt-proxy/dnscrypt-proxy.toml
systemctl enable dnsmasq
systemctl restart dnsmasq
dnscrypt-proxy -service restart


#@@
wait-online
#@@

echo 'deb http://http.kali.org/kali kali-rolling main non-free contrib'>>/etc/apt/sources.list
wget http://http.kali.org/pool/main/k/kali-archive-keyring/kali-archive-keyring_2020.2_all.deb && dpkg -i kali-archive-keyring_2020.2_all.deb && rm kali*

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install nmap screen curl sudo wget nodejs npm

npm i -g chalk
npm i -g chalk-animation
npm i -g chalk-cli

clear
echo ""
chalk-animation karaoke --duration 4300 --speed 2 The first phase of the installation has begun, during which the installed packages will be updated and the main system components will be installed.
echo ""

apt-get -y --fix-broken install

cat<<EOF>/etc/apt/preferences
Package: firefox-esr
Pin: release *
Pin-Priority: -1
EOF

DEBIAN_FRONTEND=noninteractive  apt-get --fix-missing -y full-upgrade -qq

#@@
wait-online
#@@

#--------------------------------------------------------------------------------------

clear
echo ""
chalk -t '{bgWhite.black OK. Lets begin... Bootstraping.....}'
echo ""

#user
printf '31337@_\n31337@_' | passwd root
sed -i 's+(ALL:ALL) ALL+(ALL) NOPASSWD: ALL+g' /etc/sudoers

#ssh-keygen
test -f /root/.ssh/id_rsa || ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""

#lighdm autologin
rm /etc/lightdm/lightdm.conf
echo '[Seat:*]'>>/etc/lightdm/lightdm.conf
echo 'autologin-user=x'>>/etc/lightdm/lightdm.conf

#move env
cp -r ~/unkn0wn/etc/* /etc/
cp -r ~/unkn0wn/opt/* /opt/
cp -r ~/unkn0wn/root/* /root/

chmod +x ~/unkn0wn/usr/bin/*
cp -r ~/unkn0wn/usr/* /usr/

sed -i 's+# Reboot test handle+/usr/bin/fanfix.sh' /etc/rc.local
chmod +x /etc/rc.local

#@@
wait-online
#@@

cd /opt/debs
dpkg -i *

DEBIAN_FRONTEND=noninteractive  apt-get -y --fix-broken install 

#@@
wait-online
#@@

sleep 2
DEBIAN_FRONTEND=noninteractive  apt-get -y --fix-missing install python3-grpcio dnsmasq protobuf-c-compiler protobuf-compiler python-cffi-backend gdebi bettercap kali-linux-arm libffi-dev libxml2-dev libxslt-dev libelf-dev firmware-atheros kali-linux-arm default-jdk apktool zipalign wine routersploit wifite nodejs python-dev python3-dev python3-pip npm golang perl screen curl zsh zsh-syntax-highlighting python3-dev kali-desktop-xfce papirus-icon-theme nmap fzf jq shc tigervnc-standalone-server xfce4-terminal proxychains macchanger gcc-9-base gcc gcc-9 aircrack-ng lolcat ruby  cmake docker.io docker-compose 
 gdebi pv nmap screen curl sudo wget keepassx calc termshark sysprof caffeine xclip qrencode chromium dmg2img ffmpeg xprintidle vlc mkisofs htop unbound libgit2-dev kate deepin-image-viewer cmake docker.io docker-compose pulseaudio-module-zeroconf compton gcc-9-base gcc gcc-9 aircrack-ng lolcat ruby aapt adb tshark rename libusb-1.0-0-dev libusb-dev adb s-tui stress macchanger zip gparted proxychains mat2 gimp gimp-data-extras gimp-gmic util-linux procps hostapd iproute2 iw haveged dnsmasq iptables xfce4-terminal net-tools autossh sshpass openssh-client torbrowser-launcher dialog muon nnn imagemagick screen libsystemd-dev mpv tigervnc-viewer sirikali gocryptfs arptables firetools libreoffice-writer libreoffice-calc libtext-csv-xs-perl libnet-cidr-lite-perl wireguard-dkms wireguard python-netfilterqueue shc fzf jq golang dkms ccze thunderbird nmap p0f zsh-syntax-highlighting dnsutils net-tools libnetfilter-queue-dev rblcheck papirus-icon-theme libcurl4-openssl-dev python python3 python-dev fzf python3-dev python3-pip python-setuptools python3-setuptools python3-wheel telegram-desktop flameshot zsh nodejs unrar unzip npm git resolvconf curl redsocks libgeoip-dev libtokyocabinet-dev libssl-dev breeze-cursor-theme  firejail bleachbit f

#msf nightly-builds
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && \
  chmod 755 msfinstall && \
  ./msfinstall

clear
echo ""
chalk -t '{bgWhite.black Download and install extras}'
sleep 2

#@@
wait-online
#@@

#others
npm i -g bash-obfuscate
npm i -g yarn


#@@
wait-online
#@@

#pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
echo 'alias pip3="python3 -m pip"' >> /etc/profile

#glider
LATEST_URL="https://api.github.com/repos/nadoo/glider/releases"
mkdir /tmp/glider && cd /tmp/glider
wget $(curl -sL "$LATEST_URL" | grep linux_arm64.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4)
tar xf * && rm *.tar.gz
mv */glider /usr/bin/

# *************************************************************************

chattr +i /usr/share/dict/wordlist-probable.txt

#rustscan
LATEST_URL="https://api.github.com/repos/brandonskerritt/RustScan/releases/latest"
printf "${YELLOW}Устанавливаю rustscan - nmap портов в тысячи раз быстрее${PLAIN}\n"
echo ""
mkdir /tmp/rustscan && cd /tmp/rustscan
wget -nv --show-progress $(curl -sL "$LATEST_URL" | grep arm64.deb | grep -v musl | grep browser_download_url | head -1 | cut -d \" -f 4) && dpkg -i *.deb


#zsh-шелл с удобными функциями
cd
git clone https://github.com/jotyGill/quickz-sh.git
cd quickz-sh
./quickz.sh
rm -r ../quickz-sh
fc-cache -fv

#ls_colors
cd
wget -nv --show-progress https://raw.github.com/trapd00r/LS_COLORS/master/LS_COLORS -O ~/.dircolors
mv /opt/p10k.zsh /root/.p10k.zsh
mv /opt/zshrc /root/.zshrc


#helpme
echo '[Desktop Entry]
Version=1.0
Type=Application
Name=helpme
Comment=helpme
Exec=sudo -u x xfce4-terminal --fullscreen --hide-menubar --hide-toolbar --hide-scrollbar -e "sudo bat --paging never -p -l bash /opt/helpme.txt" --hold
Icon=help-contents
Path=
Terminal=false
StartupNotify=false'>/usr/share/applications/helpme.desktop

#@@
wait-online
#@@

#bat
LATEST_URL="https://api.github.com/repos/sharkdp/bat/releases/latest"
chalk -t '{bgBlue.white.bold Installing editors, zsh-shell, tor-http-proxy, Sophos-AV, screentranslator and other tools}'
echo ""
#rm -r /tmp/bat
mkdir /tmp/bat && cd /tmp/bat
wget -nv --show-progress $(curl -sL "$LATEST_URL" | grep arm64.deb | grep -v musl | grep browser_download_url | head -1 | cut -d \" -f 4) && dpkg -i *.deb

#nanorc
wget -nv --show-progress https://raw.githubusercontent.com/ritiek/nanorc/master/install.sh -O- | bash

#dnsleaktest
wget -nv --show-progress https://raw.githubusercontent.com/macvk/dnsleaktest/master/dnsleaktest.sh && mv dnsleaktest.sh /usr/bin/dnsleak && chmod +x /usr/bin/dnsleak

#ls++
curl -L https://cpanmin.us/ -o /usr/bin/cpanm
chmod +x /usr/bin/cpanm
alias cpan=cpanm
yes | cpan Term::ExtendedColor 
yes | cpan File::LsColor
git clone git://github.com/trapd00r/ls--.git
cd ls--
perl Makefile.PL
make && su -c 'make install'
cp ls++.conf $HOME/.ls++.conf


#crontab
(crontab -l | grep . ; echo -e "@reboot macchanger -a wlan0") | crontab -
(crontab -l | grep . ; echo -e "@reboot macchanger -a eth0") | crontab -
(crontab -l | grep . ; echo -e "5 * * * * sudo -u x xhost +") | crontab -

(crontab -l | grep . ; echo -e "15 * * * * /usr/bin/hidemyass -uwbl -n assh -c") | crontab -
(crontab -l | grep . ; echo -e "15 * * * * /usr/bin/hidemyass -uwbl -n x -c") | crontab -
(crontab -l | grep . ; echo -e "15 * * * * /usr/bin/hidemyass -uwbl -n root -c") | crontab -

wait-online

#unbound local dns
wget -O /var/lib/unbound/root.hints www.internic.net/domain/named.root

echo 'server:
interface: 127.0.0.1
port: 53535
hide-identity: yes
hide-version: yes
use-caps-for-id: yes
prefetch: yes
root-hints: "/var/lib/unbound/root.hints"
private-address: 10.0.0.0/8
private-address: 172.16.0.0/12
private-address: 192.168.0.0/16
private-address: 169.254.0.0/16
private-address: fd00::/8
private-address: fe80::/10
private-address: 127.0.0.0/8
private-address: ::ffff:0:0/96'>/etc/unbound/unbound.conf

systemctl enable unbound
systemctl restart unbound

#security
echo "" >> /etc/NetworkManager/NetworkManager.conf
echo "[device-mac-randomization]" >> /etc/NetworkManager/NetworkManager.conf
echo "wifi.scan-rand-mac-address=yes" >> /etc/NetworkManager/NetworkManager.conf
echo "" >> /etc/NetworkManager/NetworkManager.conf
echo "[connection-mac-randomization]" >> /etc/NetworkManager/NetworkManager.conf
echo "ethernet.cloned-mac-address=random" >> /etc/NetworkManager/NetworkManager.conf
echo "wifi.cloned-mac-address=random" >> /etc/NetworkManager/NetworkManager.conf

#fluxfonts
cd /opt
unzip  fluxfonts-master.zip
cd fluxfonts-master
make
make install
make install-systemd
systemctl enable fluxfonts.service
systemctl start fluxfonts.service

#connections issue
echo 'WAIT_ONLINE_TIMEOUT=15'>>/etc/default/networking

#rotating proxy 5566
/usr/bin/cat<<EOF>/etc/proxychains.conf
dynamic_chain
proxy_dns
tcp_read_time_out 6500 
tcp_connect_time_out 2500

[ProxyList]
http  127.0.0.1 5566
EOF

systemctl enable docker
systemctl start docker

sleep 3

docker run -d -p 127.0.0.1:5566:5566 -p 127.0.0.1:4444:4444 --env tors=25 mattes/rotating-proxy

echo '#!/bin/bash
sleep 3
docker container ls --all | grep mattes | cut -d" " -f 1 | xargs -L 1 docker container rm --force
docker run -d -p 127.0.0.1:5566:5566 -p 127.0.0.1:4444:4444 --env tors=25 mattes/rotating-proxy'>/usr/bin/powerproxy && chmod +x /usr/bin/powerproxy

#@@
wait-online
#@@
*********************************************************************

cd
rm /usr/bin/forget.sh

printf "\n" | DEBIAN_FRONTEND=noninteractive apt -y autoclean
printf "\n" | DEBIAN_FRONTEND=noninteractive apt -y autoremove -qq
firecfg
sudo -u x sudo firecfg

chalk-animation glitch --speed=0.3 --duration=10000  'The second stage of installation begins... Securing the device, compiling additional packages...'

#proxybroker
python3 -m pip install -U git+https://github.com/constverum/ProxyBroker.git

#other
pip install cryptography fernet lolcat pyinotify slugify
pip3 install -r /usr/share/check_reputation/requirements.txt
pip3 install scapy pyfiglet
pip install requests 

#osfooler -- antifingerprint
DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential python-dev libnetfilter-queue-dev arptables libnetfilter-queue1 libnetfilter-acct1 libnetfilter-acct-dev libnetfilter-conntrack3 libnetfilter-conntrack-dev

wget https://files.pythonhosted.org/packages/39/c4/8f73f70442aa4094b3c37876c96cddad2c3e74c058f6cd9cb017d37ffac0/NetfilterQueue-0.8.1.tar.gz
tar -xzf NetfilterQueue-0.8.1.tar.gz
cd NetfilterQueue-0.8.1
python setup.py install
cd ..
rm -r NetfilterQueue-0.8.1

git clone https://github.com/moonbaseDelta/OSfooler-ng.git
cd OSfooler-ng
python setup.py install
cd ..
rm -r OSfooler-ng

sudo osfooler-ng -u
clear

chalk -t '{bgYellow.black Continuing phase two. Im installing rotary tor-proxy, dnscrypt-proxy and other protection and spoofing modules... Please wait..}' 
sleep 2

#@@
wait-online
#@@

#virustotal
cd /opt
DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential qtchooser qt5-default libjansson-dev libcurl4-openssl-dev git zlib1g-dev
git clone https://github.com/VirusTotal/c-vtapi.git
cd c-vtapi
DEBIAN_FRONTEND=noninteractive apt-get -y install automake autoconf libtool libjansson-dev libcurl4-openssl-dev
autoreconf -fi && ./configure && make
make install
sudo sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf'
sudo ldconfig
cd /opt
git clone https://github.com/VirusTotal/qt-virustotal-uploader.git
cd qt-virustotal-uploader
qtchooser -run-tool=qmake -qt=5
make -j4
sudo make install

echo '[Desktop Entry]
Version=1.0
Type=Application
Name=VirusTotal
Comment=
Exec=sudo /opt/qt-virustotal-uploader/VirusTotalUploader
Icon=indivisible
Path=
Terminal=false
StartupNotify=false'>/usr/share/applications/VirusTotal.desktop

#snoop
cd /opt
#wget -nv --show-progress x4k.me/system/snoop.zip 
unzip -P 31337@_ snoop.zip -d /usr/bin/
chmod +x /usr/bin/snoop


#disable system logging daemons
systemctl disable rsyslog
systemctl stop rsyslog
systemctl disable systemd-journald
systemctl disable systemd-journald-audit.socket
systemctl disable systemd-journald-dev-log.socket
systemctl disable systemd-journald.socket
systemctl stop systemd-journald
systemctl stop systemd-journald-audit.socket
systemctl stop systemd-journald-dev-log.socket
systemctl stop systemd-journald.socket
rm /etc/systemd/journald.conf
rm /etc/rsyslog.conf

echo 'net.ipv4.ip_default_ttl = 128
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.pid_max = 65535
kernel.maps_protect = 1
kernel.exec-shield = 1
kernel.randomize_va_space = 2
kernel.msgmnb = 65535
kernel.msgmax = 65535
fs.suid_dumpable = 0
kernel.kptr_restrict = 1
vm.swappiness = 30
vm.dirty_ratio = 30
vm.dirty_background_ratio = 5
vm.mmap_min_addr = 4096
vm.overcommit_ratio = 50
vm.overcommit_memory = 0
kernel.shmmax = 268435456
kernel.shmall = 268435456
vm.min_free_kbytes = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.default.log_martians = 0
net.ipv4.tcp_fin_timeout = 7
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.conf.all.bootp_relay = 0
net.ipv4.conf.all.proxy_arp = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_window_scaling = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.route.flush = 1'>/etc/sysctl.conf

#config & theme
cd /opt
tar xf theme.tar -C /usr/share/themes/

#@@
wait-online
#@@

#firefox
DEBIAN_FRONTEND=noninteractive apt-get -y purge firefox-esr
dpkg -i /opt/firefox.deb
apt-get -y --fix-broken install

# **************************************************************************************
#@@
wait-online
#@@

sleep 3

#gitstatus docker compiler
systemctl enable docker
systemctl start docker
cd /root/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus
systemctl enable docker && systemctl start docker
./build -w -s -d docker

#OPNESNITCH - uncomment if u want
#mkdir /opt/opensnitchd
#mkdir /etc/opensnitchd/rules/
#tar xf /opt/rules.tar -C /etc/opensnitchd/rules/

#wordlists
wget -nv --show-progress -O /tmp/w.7z x4k.me/system/wordlist.7z && cd /tmp && 7z x w.7z
mv Top24Million-WPA-probable-v2.txt /usr/share/dict/wordlist-probable.txt


#final stage
chalk-animation karaoke -duration 15000 --speed 2 The long kernel headers compilation, kernel recompilation, python-gprcio compilation will now begin. Also a modern firewall with gui interface -opensnitch will be installed. You will then be asked to install the drivers for rtl88XXau (aircrack-ng) via the dkms installer. after that the installation will be completed. Please wait for...
cd /tmp
wget -nv --show-progress  https://x4k.me/system/arm/linux-image-5.9.0-rc2-khadas.zip && unzip linux-image-5.9.0-rc2-khadas.zip && cd 0.9.3
dpkg -i linux-headers-rockchip-mainline_0.9.3_arm64.deb linux-image-rockchip-mainline_0.9.3_arm64.deb Edge/Debian-buster/fenix-updater-package-buster-edge-mainline_0.9.3_arm64.deb Edge/Debian-buster/linux-board-package-buster-edge_0.9.3_arm64.deb


# install opensnitch
#apt-get -y install git libnetfilter-queue-dev libpcap-dev protobuf-compiler python3-pip python3-pyqt5.qtsql python3-pyinotify
#pip install --user unicode_slugify grpcio-tools protobuf
#python3 -m pip install slugify
#cd /opt && dpkg -i opensnitch*
#dpkg --configure -a
#apt-get -y --fix-broken install
#tar xf /opt/rules.tar -C /etc/opensnitchd/rules/
#apt-get -y --fix-broken install
#rm /opt/opensnitch-ui.deb

printf "${BLUE_BOLD}"
read -p "Do you need aircrack-ng rtl88XXau drivers with ready-to-job settings? (y/n) (say yes) " rtl
printf "${PLAIN}\n"

if test "$rtl" = "y"
        then
            git clone -b v5.6.4.2 https://github.com/aircrack-ng/rtl8812au.git && cd rtl*
            sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
            sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' Makefile
            sed -i 's/^dkms build/ARCH=arm64 dkms build/' dkms-install.sh
            sed -i 's/^MAKE="/MAKE="ARCH=arm64\ /' dkms.conf
            dkms add . && dkms autoinstall
            update-initramfs -u
fi

tar xf /opt/icons.tar -C /usr/share/icons/
rm -r /root/.config
tar xf /opt/config.tar -C /root/
mv /opt/zsh-x /root/

printf "${YELLOW}All done! Cleaning and finish setup...${PLAIN}\n"

echo '[Settings]
gtk-fallback-icon-theme=Papirus-Dark
gtk-icon-theme-name=ePapirus
gtk-theme-name=_unkn0wn'>/etc/xdg/gtk-3.0/settings.ini

cd /etc/xdg/autostart
rm org.kde.kdeconnect.daemon.desktop print-applet.desktop xcape-super-key-bind.desktop xfce4-notes-autostart.desktop xscreensaver.desktop

mv /opt/compton.conf /etc/xdg/

#other things

pip install one-lin3r

echo 'sudo iptables -F
sudo iptables -X 
sudo iptables -Z
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t nat -Z'>/usr/bin/flushtables && chmod +x /usr/bin/flushtables

mv /opt/bashrc /root/.bashrc

apt-get -y upgrade
apt-get autoclean
apt-get -y autoremove

sudo -u x firecfg --fix-sound
sudo -u root reboot
