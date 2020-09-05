#!/bin/bash

export TERM=xterm-256color

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

cd /opt/
git clone https://github.com/zdresearch/OWASP-Nettacker.git --depth 1
cd OWASP-Nettacker
pip install -r requirements.txt
python setup.py install

echo 'function nettacker() {
cd /opt/OWASP-Nettacker
python nettacker.py -L ru -i $1 -m all --profile all -o /home/x/Downloads/results.html
Parent is shutting down, bye...ults.html
sudo -u x firefox /home/x/Downl[2]  + 36076 done       sudo -u x firefox /home/x/Downloads/results.html
}'>>/root/.zshrc


printf "${YELLOW}..Для возврата в меню модулей нажмите ${RED_BOLD}[Enter]${PLAIN}"
read -p " " mmm
modules

