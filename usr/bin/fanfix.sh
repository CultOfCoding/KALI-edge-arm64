#!/bin/bash

{
while true; do

temp=$(sudo /usr/local/bin/fan.sh temp | awk '{print $3}')

thigh=$((55000))
tnorm=$((45000))
tgood=$((40000))

if (( $temp > $thigh )); then
        /usr/local/bin/fan.sh high

elif (( $temp<$thigh&&$temp>$tnorm )); then
        /usr/local/bin/fan.sh mid

elif (( $temp < $tgood )); then
        /usr/local/bin/fan.sh off

else
        /usr/local/bin/fan.sh low
fi

sleep 3

done
}&>/dev/null

