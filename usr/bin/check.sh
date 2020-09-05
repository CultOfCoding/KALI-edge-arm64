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

ipinfo() {
    external_ip="$1"
    result=$(curl --silent https://ipinfo.io/$external_ip)

    json_ip=$(echo "$result" | jq -r ".ip")
    json_hostname=$(echo "$result" | jq -r ".hostname")
    json_city=$(echo "$result" | jq -r ".city")
    json_region=$(echo "$result" | jq -r ".region")
    json_country=$(echo "$result" | jq -r ".country")
    json_loc=$(echo "$result" | jq -r ".loc")
    json_org=$(echo "$result" | jq -r ".org")
    json_postal=$(echo "$result" | jq -r ".postal")

    printf "${GREEN_BOLD}IP-Address: ${PLAIN}${json_ip}\n"
    printf "${GREEN_BOLD}Hostname: ${PLAIN}${json_hostname}\n"
    printf "${GREEN_BOLD}Network: ${PLAIN}${json_org}\n"
    printf "${GREEN_BOLD}City: ${PLAIN}${json_city}, ${json_region}, ${json_country}\n"
    printf "${GREEN_BOLD}Postal Code: ${PLAIN}${json_postal}\n"
    printf "${GREEN_BOLD}Latitude/Longitude: ${PLAIN}${json_loc}\n"
}

echo ""
ipinfo $1

echo ""
printf "${RED_BOLD}Блэклист:${GREEN}" 

echo ""
rblcheck $1 | grep "not listed"
printf "${RED}"
rblcheck $1 | grep -v "not listed"

printf "\n${GREEN}Порт: "
portcheck=$(nmap -p $2 $1 | sed -n 6p)
if [ -n "$portcheck" ]
then

nmap -p $2 $1 | sed -n 6p
printf "\n${YELLOW}Пинг: ${PLAIN}"
prettyping --nolegend -c 5 $1 | sed -n 2p
printf "\n${GREEN_BOLD}                                                          ЖИВОЙ!!!${PLAIN}\n"

elif [ -z "$portcheck" ]
then

printf "${RED_BOLD}Подключение отсутствует :( \n
                                                          МЕРТЫЙ >:( ${PLAIN}\n"
fi

