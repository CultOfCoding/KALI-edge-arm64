#!/bin/bash
apt-get -y install metasploit-framework openjdk-8-jdk apktool zipalign wine

cd /usr/share
    git clone https://github.com/AngelSecurityTeam/RapidPayload
    cd RapidPayload
    bash install.sh
    python3 RapidPayload.py

