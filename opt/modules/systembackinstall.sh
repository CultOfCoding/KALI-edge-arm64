#!/bin/bash

wget https://raw.githubusercontent.com/l4ckyguy/others/master/systemback-install_pack-1.9.3.tar.xz
tar xvf systemback-install_pack-1.9.3.tar.xz
cd systemback-install_pack-1.9.3/
printf '1' | ./install.sh
apt -y --fix-broken install
cd ~/unkn0wn
modules
