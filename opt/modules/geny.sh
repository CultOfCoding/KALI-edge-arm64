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

clear

echo ""
printf "${YELLOW_BOLD}Загружаю необходимые файлы.. Жди!${PLAIN}\n"
echo "..."

{
mkdir /tmp/an && cd /tmp/an
wget x4k.me/system/android/all.tar && tar xf all.tar
mkdir /home/x/droidfiles && mv *.apk /home/x/droidfiles
chown -hR x:x /home/x/droidfile
}&>/dev/null

echo ...

printf "${YELLOW}Загрузка завершена, начинаю установку..${PLAIN}\n"

sleep 2
yes | ./genymotion-3.1.0-linux_x64.bin
chown -hR x:x /opt/genymobile
sudo -u x /opt/genymobile/genymotion/gmtool config username=tebya@poime.li password=P@p31337 license_server off

#echo ""
#printf "${RED}Ожидайте. Загружается образ-пример настроенной VM.. Размер загружаемого файла - 2GB${PLAIN}\n"
#echo ""

#{
#cd /home/x/
#rm -r .Genymobile
#}&>/dev/null

#wget http://x4k.me/system/geny.zip

#{
#unzip -P "31337@_" geny.zip
#chown -hR x:x /home/x/.Genymobile
#rm geny.zip
#}&>/dev/null

echo ""
echo ""
printf "${RED_BOLD}Genymotion${GREEN_BOLD} успешно установлен!\n
${PLAIN} После запуска, укажите ${YELLOW} Personal use${PLAIN} на вопрос о лицензии.\n
Необходимые утилиты Вы сможете найти в ${BLUE_BOLD}/home/x/droidfiles${PLAIN}. Для установки просто перетащите файлы в окно эмулятора\n"

printf "${YELLOW}..Для возврата в меню модулей нажмите ${RED_BOLD}[Enter]${PLAIN}"
read -p " " mmm
modules
