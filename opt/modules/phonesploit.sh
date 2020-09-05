#!/bin/bash

apt-get -y install android-tools-adb android-tools-fastboot

cd /opt/
git clone https://github.com/Zucccs/PhoneSploit --depth 1
cp /opt/modules/phonesploit.py /opt/PhoneSploit/main_linux.py
cd PhoneSploit
pip install colorama

/usr/bin/cat<<EOF>phonesploit
#!/bin/bash

sudo -u x firefox  https://www.shodan.io/search?query=android+debug+bridge+product%3A”Android+Debug+Bridge” &
cd /opt/modules/PhoneSploit
sudo -u x xfce4-terminal -e "sudo python2 /opt/PhoneSploit/main_linux.py"
EOF
shc -f phonesploit -o /usr/bin/phonesploit
rm phonesploit.x.c
