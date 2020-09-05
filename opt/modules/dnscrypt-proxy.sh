#!/bin/bash

{
cloudflared -service uninstall
cloudflared -service stop

killall dotnet

systemctl disable dns
systemctl stop dns
}&>/dev/null

dnscrypt-proxy -service install
dnscrypt-proxy -service start

modules

