#!/bin/bash

apt-get -y install metasploit-framework

pip install beautifulsoup4 tabulate termcolor python-libnmap lxml
cd /tmp && git clone https://github.com/SpiderLabs/msfrpc
cd msfrpc && cd python-msfrpc && python setup.py install
pip install msgpack-python

cd /opt
git clone https://github.com/milo2012/metasploitHelper.git

echo '#!/bin/bash
cd /opt/metasploitHelper
python msfHelper.py $1 -a -i -n 10 -u -v'>>/usr/bin/msfhelper && chmod +x /usr/bin/msfhelper

x4ks
