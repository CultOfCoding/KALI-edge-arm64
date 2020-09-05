#!/bin/bash

COLOR_RST="\e[0m"
COLOR_CYAN_BOLD="\e[1;36m"
DIR_PUB="/pub"
DIR_PUB_LOOT="$DIR_PUB/loot"
DIR_PUB_TOOLS="$DIR_PUB/tools"
DIR_PUB_TEMP="$DIR_PUB/temp"
DIR_TOOLS="/opt"
DIR_TOOLS_WEB="$DIR_TOOLS/web"
DIR_TOOLS_RECON="$DIR_TOOLS/recon"
DIR_TOOLS_AD="$DIR_TOOLS/ad"
DIR_TOOLS_EXPLOIT="$DIR_TOOLS/exploit"
DIR_TOOLS_POST_EXPLOIT="$DIR_TOOLS/post-exploit"
DIR_TOOLS_PRIVESC="$DIR_TOOLS/privesc"
DIR_TOOLS_PIVOT="$DIR_TOOLS/pivot"
DIR_TOOLS_WINDOWS="$DIR_TOOLS/windows"
DIR_TOOLS_NETWORK="$DIR_TOOLS/network"
DIR_TOOLS_AV_BYPASS="$DIR_TOOLS/av-bypass"
DIR_TOOLS_MISC="$DIR_TOOLS/misc"
USER_NAME=$(logname)
USER_HOME=$(eval echo ~$USER_NAME)

function get_latest_github_release() {
    # Usage: get_latest_github_release "gentilkiwi/mimikatz"
    github_url="https://api.github.com/repos/$1/releases/latest"
    releases="$(curl --silent $github_url)"
    urls="$(echo $releases | jq -r '.assets[] | select(.).browser_download_url')" # Get the url of each entry
    version="$(echo $releases | jq -r '.tag_name')" # Get last version number
    echo -e "$COLOR_CYAN_BOLD[*] VERSION: $version$COLOR_RST"
    echo "$github_url,$version" > .release
    for u in $(echo -e $urls)
    do
        echo -e "$COLOR_CYAN_BOLD[*] URL: $u$COLOR_RST"
        wget --quiet "$u"
        filefullname="${u##*/}"
        filename="${filefullname%.*}"
        fileext="${filefullname##*.}"
        if [ "$fileext" == "zip" ]
        then
            echo -e "$COLOR_CYAN_BOLD[*] ZIP archive: $filefullname$COLOR_RST"
            unzip "$filefullname" 1>/dev/null
            rm -f "$filefullname"
        elif [ "$fileext" == "gz" ]
        then
            echo -e "$COLOR_CYAN_BOLD[*] GZIP archive: $filefullname$COLOR_RST"
            gzip -d "$filefullname" 
        elif [ "$fileext" == "7z" ]
        then
            echo -e "$COLOR_CYAN_BOLD[*] 7Z archive: $filefullname$COLOR_RST"
            7z d "$filefullname" 1>/dev/null
            rm -f "$filefullname" 
        fi
    done
}

function get_plink_binaries() {
    url="https://the.earth.li/~sgtatham/putty/latest/w32/plink.exe"
    echo -e "$COLOR_CYAN_BOLD[*] URL: $url.$COLOR_RST"
    wget --quiet "$url" -O "plink32.exe"

    url="https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe"
    echo -e "$COLOR_CYAN_BOLD[*] URL: $url.$COLOR_RST"
    wget --quiet "$url" -O "plink64.exe"  
}

function get_netcat_win32_binaries() {
    url="https://eternallybored.org/misc/netcat/netcat-win32-1.12.zip"
    echo -e "$COLOR_CYAN_BOLD[*] URL: $url.$COLOR_RST"
    wget --quiet "$url"  
    unzip *.zip 
    rm *.zip
}

function get_sysinternals_binaries() {
    url="https://download.sysinternals.com/files/SysinternalsSuite.zip"
    echo -e "$COLOR_CYAN_BOLD[*] URL: $url.$COLOR_RST"
    wget --quiet "$url" 
    unzip *.zip
    rm *.zip
}

function install_updates () {
    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
}

function apt_install_silently () {
    for p in $*
    do
        echo -e "$COLOR_CYAN_BOLD[*] Installing: $p$COLOR_RST"
        apt-get install -y $p >/dev/null 2>&1
    done
}

function install_packages () {
    ### Misc tools
    packages="libc6-dev-i386 gedit terminator htop ftp python-pip python2-dev python3 python3-dev python3-pip gdb libcapstone3 libcapstone-dev cmake rsh-client ent strace tsocks dbeaver sqlite jq gvfs-backends rlwrap checksec gdb ltrace strace mingw-w64" 
    apt_install_silently $packages

    ### Pentest tools 
    packages="hostapd hostapd-wpe crackmapexec ncat nfs-common libimage-exiftool-perl bloodhound gobuster odat nss-passwords zmap"
    apt_install_silently $packages

    ln -s $(which crackmapexec) "/usr/bin/cme"

    ### Collections of tools 
    packages="nishang seclists payloadsallthethings powersploit"
    apt_install_silently $packages
}

function install_snapd () {
    apt_install_silently snapd
    systemctl enable --now snapd apparmor
    snap install code --classic
}

function install_jekyll () {
    gem install jekyll
    gem install jekyll-feed
    gem install jemoji
}

function configure_aliases () {
    alias_file="$USER_HOME/.bash_aliases"
    sudo -u $USER_NAME bash -c "echo alias ll=\\\"ls -alh\\\" >> $alias_file"
    sudo -u $USER_NAME bash -c "echo alias pyweb=\\\"$DIR_TOOLS_MISC/Pentest-Tools/pwnbox/pyweb.sh\\\" >> $alias_file"
    sudo -u $USER_NAME bash -c "echo alias ipa=\\\"ip -c -h a\\\" >> $alias_file"

    sudo -u $USER_NAME bash -c "echo 'export PATH=\$PATH:/sbin:/usr/sbin' >> $USER_HOME/.bashrc"
}

function configure_terminator () {
    terminator_dir="$USER_HOME/.config/terminator"
    terminator_config="$terminator_dir/config"
    sudo -u $USER_NAME bash -c "mkdir -p $terminator_dir"
    sudo -u $USER_NAME bash -c "echo \"W2dsb2JhbF9jb25maWddCiAgc21hcnRfY29weSA9IEZhbHNlCiAgc3VwcHJlc3NfbXVsdGlwbGVfdGVybV9kaWFsb2cgPSBUcnVlCiAgdGl0bGVfZm9udCA9IFNhbnMgMTAKICB0aXRsZV9pbmFjdGl2ZV9iZ19jb2xvciA9ICIjODg4YTg1IgogIHRpdGxlX3RyYW5zbWl0X2JnX2NvbG9yID0gIiM2YjAwMDAiCiAgdGl0bGVfdHJhbnNtaXRfZmdfY29sb3IgPSAiI2VlZWVlYyIKICB0aXRsZV91c2Vfc3lzdGVtX2ZvbnQgPSBGYWxzZQpba2V5YmluZGluZ3NdCltsYXlvdXRzXQogIFtbZGVmYXVsdF1dCiAgICBbW1tjaGlsZDBdXV0KICAgICAgZnVsbHNjcmVlbiA9IEZhbHNlCiAgICAgIGxhc3RfYWN0aXZlX3Rlcm0gPSA3YWZhODdlMC01ODI4LTQwOGItYWY0MC1kYTQ5MjNlODE5MDYKICAgICAgbGFzdF9hY3RpdmVfd2luZG93ID0gVHJ1ZQogICAgICBtYXhpbWlzZWQgPSBUcnVlCiAgICAgIG9yZGVyID0gMAogICAgICBwYXJlbnQgPSAiIgogICAgICBwb3NpdGlvbiA9IDA6MjcKICAgICAgc2l6ZSA9IDE2MDAsIDgwMAogICAgICB0aXRsZSA9IFRlcm1pbmF0b3IKICAgICAgdHlwZSA9IFdpbmRvdwogICAgW1tbY2hpbGQxXV1dCiAgICAgIG9yZGVyID0gMAogICAgICBwYXJlbnQgPSBjaGlsZDAKICAgICAgcG9zaXRpb24gPSA0MDAKICAgICAgcmF0aW8gPSAwLjUKICAgICAgdHlwZSA9IFZQYW5lZAogICAgW1tbY2hpbGQyXV1dCiAgICAgIG9yZGVyID0gMAogICAgICBwYXJlbnQgPSBjaGlsZDEKICAgICAgcG9zaXRpb24gPSA4MDAKICAgICAgcmF0aW8gPSAwLjUKICAgICAgdHlwZSA9IEhQYW5lZAogICAgW1tbY2hpbGQ1XV1dCiAgICAgIG9yZGVyID0gMQogICAgICBwYXJlbnQgPSBjaGlsZDEKICAgICAgcG9zaXRpb24gPSA4MDEKICAgICAgcmF0aW8gPSAwLjUwMDYyNQogICAgICB0eXBlID0gSFBhbmVkCiAgICBbW1t0ZXJtaW5hbDNdXV0KICAgICAgb3JkZXIgPSAwCiAgICAgIHBhcmVudCA9IGNoaWxkMgogICAgICBwcm9maWxlID0gZGVmYXVsdAogICAgICB0eXBlID0gVGVybWluYWwKICAgICAgdXVpZCA9IDdhZmE4N2UwLTU4MjgtNDA4Yi1hZjQwLWRhNDkyM2U4MTkwNgogICAgW1tbdGVybWluYWw0XV1dCiAgICAgIG9yZGVyID0gMQogICAgICBwYXJlbnQgPSBjaGlsZDIKICAgICAgcHJvZmlsZSA9IGRlZmF1bHQKICAgICAgdHlwZSA9IFRlcm1pbmFsCiAgICAgIHV1aWQgPSAyOGE4MzIxNS0yNTk4LTRiZTEtOGRkMy05NjdmNjkzNTQxNGUKICAgIFtbW3Rlcm1pbmFsNl1dXQogICAgICBvcmRlciA9IDAKICAgICAgcGFyZW50ID0gY2hpbGQ1CiAgICAgIHByb2ZpbGUgPSBkZWZhdWx0CiAgICAgIHR5cGUgPSBUZXJtaW5hbAogICAgICB1dWlkID0gNGI2ZGExMmUtM2VkOS00OTBiLWI0MGQtYjYxN2Y4NWQyMDY4CiAgICBbW1t0ZXJtaW5hbDddXV0KICAgICAgb3JkZXIgPSAxCiAgICAgIHBhcmVudCA9IGNoaWxkNQogICAgICBwcm9maWxlID0gZGVmYXVsdAogICAgICB0eXBlID0gVGVybWluYWwKICAgICAgdXVpZCA9IGRhMTAwMTc5LThhYmItNDljZS04NzZhLTIxNjBjM2MzOTc0ZApbcGx1Z2luc10KW3Byb2ZpbGVzXQogIFtbZGVmYXVsdF1dCiAgICBjdXJzb3JfY29sb3IgPSAiI2VlZWVlYyIKICAgIGN1cnNvcl9jb2xvcl9mZyA9IEZhbHNlCiAgICBmb250ID0gTW9ub3NwYWNlIDkKICAgIGZvcmVncm91bmRfY29sb3IgPSAiI2ZmZmZmZiIKICAgIGljb25fYmVsbCA9IEZhbHNlCiAgICBzY3JvbGxiYWNrX2luZmluaXRlID0gVHJ1ZQogICAgdXNlX3N5c3RlbV9mb250ID0gRmFsc2UKCg==\" | base64 -d > $terminator_config"
}

function configure_smb_share () {
    smb_config="/etc/samba/smb.conf"
    smb_config_bak="/etc/samba/smb.conf.bak"
    html_default='<html><body bgcolor="#000000"><h1><center><font color="#cc0000">WhAt ArE yOu DoInG tHeRe???</font></center></h1></body></html>'
    mv $smb_config $smb_config_bak
    adduser --system shareuser
    mkdir -p $DIR_PUB_LOOT $DIR_PUB_TOOLS $DIR_PUB_TEMP
    chmod ugo=rwx $DIR_PUB
    chmod u=rwx,go=wx $DIR_PUB_LOOT # We can write but not list its content
    chmod u=rwx,go=rx $DIR_PUB_TOOLS # We can read/execute but not write 
    chmod 777 $DIR_PUB_TEMP # All access on the temp folder 
    echo "W2dsb2JhbF0KICAgIG1hcCB0byBndWVzdCA9IEJhZCBVc2VyCiAgICBsb2cgZmlsZSA9IC92YXIvbG9nL3NhbWJhLyVtCiAgICBsb2cgbGV2ZWwgPSAxCiAgICBzZWN1cml0eSA9IHVzZXIKICAgIHBhc3NkYiBiYWNrZW5kID0gdGRic2FtICAKCltwdWIkXQogICAgIyBTaGFyZSBkZXNjcmlwdGlvbiAKICAgIGNvbW1lbnQgPSBBbGwgUHJpbnRlcnMgIAogICAgIyBMb2NhbCBmb2xkZXIgdG8gc2hhcmUgCiAgICBwYXRoID0gL3B1YgogICAgIyBNYWtlIGl0ICdpbnZpc2libGUnCiAgICBicm93c2VhYmxlID0gbm8KICAgICMgRW5hYmxlIGFub255bW91cyBhY2Nlc3MgCiAgICBwdWJsaWMgPSB5ZXMKICAgIGd1ZXN0IG9rID0geWVzCiAgICAjIE5vdCBhIHByaW50ZXIgc2hhcmUgCiAgICBwcmludGFibGUgPSBubwogICAgIyBUaGUgc2hhcmUgaXMgbm90IHJlYWQtb25seSAobG9vdCBmb2xkZXIpCiAgICByZWFkIG9ubHkgPSBubwogICAgIyBFbmFibGUgd3JpdGUgYWNjZXNzIAogICAgd3JpdGFibGUgPSB5ZXMKICAgICMgRW5hYmxlIGhpZGRlbiBmaWxlcyAoc3RhcnRpbmcgd2l0aCBhIGRvdCkKICAgIGhpZGUgZG90IGZpbGVzID0geWVzCiAgICAjIEhpZGUgZm9sZGVycyAvIGV4dGVuc2lvbnMgCiAgICAjaGlkZSBmaWxlcyA9IC8qLwogICAgZm9yY2UgdXNlciA9IHNoYXJldXNlcgo=" | base64 -d > $smb_config
    echo $html_default > "$DIR_PUB/index.html"
    echo $html_default > "$DIR_PUB_TOOLS/index.html"
    echo $html_default > "$DIR_PUB_LOOT/index.html"
    service smbd stop
    service smbd start
    service smbd stop
}

function configure_metasploit () {
    systemctl start postgresql
    update-rc.d postgresql enable
    msfdb init
}

function install_web_tools () {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_WEB
    cd $DIR_TOOLS_WEB
    
    # dirsearch 
    git clone "https://github.com/maurosoria/dirsearch.git" --depth 1
    ln -s "$DIR_TOOLS_WEB/dirsearch/dirsearch.py" "/usr/bin/dirsearch.py"
    
    # Get CMSmap
    git clone "https://github.com/Dionach/CMSmap" --depth 1
    cd "CMSmap"
    pip3 install .
    cd ..
    
    # Get GitTools
    git clone "https://github.com/internetwache/GitTools.git" --depth 1
    
    # Get b374k PHP webshell 
    git clone "https://github.com/b374k/b374k.git" --depth 1 
    
    # Get and Magescan 
    wget "https://github.com/steverobbins/magescan/releases/download/v1.12.7/magescan.phar" 
    
    # Get phpggc
    git clone "https://github.com/ambionics/phpggc.git" --depth 1 
    
    # Get testssl.sh 
    git clone "https://github.com/drwetter/testssl.sh.git" --depth 1
    ln -s "$DIR_TOOLS_WEB/testssl.sh/testssl.sh" "/usr/bin/testssl.sh"
    
    # Get MageScan
    git clone "https://github.com/steverobbins/magescan.git" --depth 1 
    
    # Get reGeorg
    git clone "https://github.com/sensepost/reGeorg.git" --depth 1

    # Get IIS Shortname scanner
    git clone "https://github.com/irsdl/IIS-ShortName-Scanner" --depth 1

    cd $CWD_OLD
}

function install_recon_tools () {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_RECON
    cd $DIR_TOOLS_RECON
    
    # Get Sublist3r
    git clone "https://github.com/aboul3la/Sublist3r.git" --depth 1 
    cd "Sublist3r"
    pip install -r requirements.txt
    pip3 install -r requirements.txt
    cd .. 
    
    cd $CWD_OLD
}

function install_ad_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_AD
    cd $DIR_TOOLS_AD
    
    # impacket 
    git clone "https://github.com/CoreSecurity/impacket.git" --depth 1
    cd "impacket"
    pip3 install .
    cd ..
    
    # Get BloodHound repo
    git clone "https://github.com/BloodHoundAD/BloodHound" --depth 1
    
    # Get Bloodhound Python script 
    git clone "https://github.com/fox-it/BloodHound.py" --depth 1
    
    cd $CWD_OLD
}

function install_exploit_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_EXPLOIT
    cd $DIR_TOOLS_EXPLOIT

    # Pwn tools
    pip3 install pwn
    
    # WebDav
    pip3 install wsgidav cheroot python-pam
    
    # Get eternalblue ptyhon exploit 
    git clone "https://github.com/vivami/MS17-010" --depth 1 
    
    # Get JDWP Shellifier 
    git clone "https://github.com/IOActive/jdwp-shellifier.git" --depth 1
    
    # Java deserialization exploits
    git clone "https://github.com/Coalfire-Research/java-deserialization-exploits.git" --depth 1 
    
    # Get GEF (GDB Enhanced Features)
    git clone "https://github.com/hugsy/gef.git" --depth 1
    pip3 install capstone ropper # Python3 optional dependencies
    sudo -u $USER_NAME bash -c "echo \"source $DIR_TOOLS_EXPLOIT/gef/gef.py\" >> \"$USER_HOME/.gdbinit\""
    
    cd $CWD_OLD
}

function install_post_exploit_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_POST_EXPLOIT
    cd $DIR_TOOLS_POST_EXPLOIT

    # Get Powercat
    git clone "https://github.com/besimorhino/powercat.git" --depth 1 
    
    # Outils PowerShell (dont reverse shell TCP)
    git clone "https://github.com/PowerShellMafia/PowerSploit.git" --depth 1
    
    # Get firefox_decrypt
    git clone "https://github.com/unode/firefox_decrypt.git" --depth 1 
    
    # Get websphere-xor-password-decode-encode.py
    wget "https://github.com/interference-security/scripts-tools-shells/raw/master/websphere-xor-password-decode-encode.py"
    
    # Get Evil WinRM and install dependencies 
    git clone "https://github.com/Hackplayers/evil-winrm" --depth 1 
    cd evil-winrm
    gem install evil-winrm
    cd ..
    
    # Get Mimikatz binaries 
    mkdir "mimikatz-bin"
    cd "mimikatz-bin"
    get_latest_github_release "gentilkiwi/mimikatz"
    cd ..

    cd $CWD_OLD
}

function install_privesc_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_PRIVESC
    cd $DIR_TOOLS_PRIVESC

    # Get linuxprivchecker.py
    git clone "https://github.com/sleventyeleven/linuxprivchecker" --depth 1 
    
    # Get LinEnum
    git clone "https://github.com/rebootuser/LinEnum.git" --depth 1
    
    # Get PrivescCheck
    git clone "https://github.com/itm4n/PrivescCheck" --depth 1

    # Get PsPy
    mkdir pspy-bin
    cd pspy-bin
    get_latest_github_release "DominicBreuker/pspy"
    cd ..
    
    cd $CWD_OLD
}

function install_pivot_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_PIVOT
    cd $DIR_TOOLS_PIVOT
    
    # Get plink 
    mkdir "plink-bin"
    "plink-bin"
    get_plink_binaries
    cd ..
    
    # Get chisel binaries 
    mkdir "chisel-bin"
    cd "chisel-bin"
    get_latest_github_release "jpillora/chisel"
    cd ..
    
    # Get netcat for Windows 
    mkdir "netcat-win32-bin"
    "netcat-win32-bin"
    get_netcat_win32_binaries
    cd .. 
    
    cd $CWD_OLD
}

function install_windows_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_WINDOWS
    cd $DIR_TOOLS_WINDOWS
    
    # Windows Sysinternals Suite
    mkdir "sysinternals-bin"
    cd "sysinternals-bin"
    get_sysinternals_binaries
    cd .. 
    
    cd $CWD_OLD
}

function install_network_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_NETWORK
    cd $DIR_TOOLS_NETWORK
    
    # Get eaphammer
    git clone "https://github.com/s0lst1c3/eaphammer.git" --depth 1
    # Get hcxdumptool (wifite recommended app)
    apt_install_silently libcurl4-openssl-dev libssl-dev
    git clone https://github.com/ZerBea/hcxdumptool.git --depth 1
    cd hcxdumptool
    make && make install && echo -e "$COLOR_CYAN_BOLD[*] hcxdumptool setup complete.$COLOR_RST"
    cd ..
    
    # Get hcxtools (wifite recommended app)
    git clone https://github.com/ZerBea/hcxtools.git --depth 1
    cd hcxtools
    make && make install && echo -e "$COLOR_CYAN_BOLD[*] hcxtools setup complete.$COLOR_RST"
    cd ..
    
    # Get Pyrit (wifite recommended app)
    git clone https://github.com/JPaulMora/Pyrit.git --depth 1
    apt_install_silently python-scapy libpq-dev libpcap-dev
    pip install psycopg2 scapy
    cd Pyrit
    python setup.py clean && python setup.py build && python setup.py install && echo -e "$COLOR_CYAN_BOLD[*] Pyrit setup complete.$COLOR_RST"
    
    cd $CWD_OLD
}

function install_av_bypass_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_AV_BYPASS
    cd $DIR_TOOLS_AV_BYPASS
    
    # Get PyFuscation
    git clone "https://github.com/CBHue/PyFuscation.git" --depth 1
    
    cd $CWD_OLD
}

function install_misc_tools() {
    CWD_OLD=$(pwd)
    mkdir -p $DIR_TOOLS_MISC
    cd $DIR_TOOLS_MISC
    
    # Get Pentest-Tools
    git clone "https://github.com/itm4n/Pentest-Tools.git" --depth 1 
    
    cd $CWD_OLD
}

function populate_pub_tools() {
    # Copy chisel binaries 
    cp "$DIR_TOOLS_PIVOT/chisel-bin/*_linux_386" "$DIR_PUB_TOOLS/chisel32.elf"
    cp "$DIR_TOOLS_PIVOT/chisel-bin/*_linux_arm64" "$DIR_PUB_TOOLS/chisel64.elf"
    cp "$DIR_TOOLS_PIVOT/chisel-bin/*_windows_386.exe" "$DIR_PUB_TOOLS/chisel32.exe"
    cp "$DIR_TOOLS_PIVOT/chisel-bin/*_windows_arm64.exe" "$DIR_PUB_TOOLS/chisel64.exe"

    # Copy plink binaries 
    cp "$DIR_TOOLS_PIVOT/plink-bin/plink32.exe" "$DIR_PUB_TOOLS/plink32.exe"
    cp "$DIR_TOOLS_PIVOT/plink-bin/plink64.exe" "$DIR_PUB_TOOLS/plink64.exe"

    # Copy netcat binaires 
    cp "$DIR_TOOLS_PIVOT/netcat-win32-bin/nc.exe" "$DIR_PUB_TOOLS/nc32.exe"
    cp "$DIR_TOOLS_PIVOT/netcat-win32-bin/nc64.exe" "$DIR_PUB_TOOLS/nc64.exe"

    # Copy Mimikatz binaries 
    cp "$DIR_TOOLS_POST_EXPLOIT/mimikatz-bin/Win32/mimikatz.exe" "$DIR_PUB_TOOLS/mimikatz32.exe"
    cp "$DIR_TOOLS_POST_EXPLOIT/mimikatz-bin/x64/mimikatz.exe" "$DIR_PUB_TOOLS/mimikatz64.exe"

    # Bloodhound ingestors 
    cp "$DIR_TOOLS_AD/BloodHound/Ingestors/SharpHound.exe" $DIR_PUB_TOOLS
    cp "$DIR_TOOLS_AD/BloodHound/Ingestors/SharpHound.ps1" $DIR_PUB_TOOLS

    # Sysinternals 
    cp "$DIR_TOOLS_WINDOWS/sysinternals-bin/ADExplorer.exe" "$DIR_PUB_TOOLS/adexplorer.exe"
    cp "$DIR_TOOLS_WINDOWS/sysinternals-bin/procdump64.exe" "$DIR_PUB_TOOLS" 
    cp "$DIR_TOOLS_WINDOWS/sysinternals-bin/PsExec.exe" "$DIR_PUB_TOOLS/psexec32.exe" 
    cp "$DIR_TOOLS_WINDOWS/sysinternals-bin/PsExec64.exe" "$DIR_PUB_TOOLS/psexec64.exe"
    cp "$DIR_TOOLS_WINDOWS/sysinternals-bin/procdump.exe" "$DIR_PUB_TOOLS/procdump32.exe"
    cp "$DIR_TOOLS_WINDOWS/sysinternals-bin/procdump64.exe" "$DIR_PUB_TOOLS/procdump64.exe"

    # Copy LinEnum
    cp "$DIR_TOOLS_PRIVESC/LinEnum/LinEnum.sh" "$DIR_PUB_TOOLS/LinEnum.sh"

    # Misc 
    cp "$(locate 'Invoke-SessionGopher.ps1' | grep 'nishang')" $DIR_PUB_TOOLS
    cp "$DIR_TOOLS_POST_EXPLOIT/powercat/powercat.ps1" $DIR_PUB_TOOLS
    cp "$DIR_TOOLS_POST_EXPLOIT/PowerSploit/Privesc/PowerUp.ps1" $DIR_PUB_TOOLS
    cp "$DIR_TOOLS_POST_EXPLOIT/PowerSploit/Recon/PowerView.ps1" $DIR_PUB_TOOLS

    chmod 755 "$DIR_PUB_TOOLS/"*.elf
    chmod 755 "$DIR_PUB_TOOLS/"*.exe
    chmod 644 "$DIR_PUB_TOOLS/"*.ps1
}

function save_custom_scripts() {
    # Udpate script
    update_script="$DIR_TOOLS_MISC/Pentest-Tools/pwnbox/pwnbox-update.sh"
    chmod +x $update_script
    ln -s $update_script "/usr/bin/pwnbox-update"
}

function set_xfce_custom_settings() {
    # Power management > Display > Blank after: Never 
    xfconf-query -c "xfce4-power-manager" -p "/xfce4-power-manager/blank-on-ac" -s 0
    # Power management > Display > Put to sleep after: Never
    xfconf-query -c "xfce4-power-manager" -p "/xfce4-power-manager/dpms-on-ac-sleep" -s 0
    # Power management > Display > Switch off after: Never
    xfconf-query -c "xfce4-power-manager" -p "/xfce4-power-manager/dpms-on-ac-off" -s 0
    # Desktop > Background > Wallpaper
    xfconf-query -c "xfce4-desktop" -p "/backdrop/screen0/monitorVirtual1/workspace0/last-image" -s "/usr/share/backgrounds/kali/kali-small-logo.png"
    # Panel > Rwo size: 36
    xfconf-query -c "xfce4-panel" -p "/panels/panel-1/size" -s 36
    # Panel > Don't show Window titles
    xfconf-query -c "xfce4-panel" -p "/plugins/plugin-12/show-labels" -s false
}

function full_install() {
    echo -e "$COLOR_CYAN_BOLD[*] Installing updates.$COLOR_RST"
    install_updates
    echo -e "$COLOR_CYAN_BOLD[*] Installing packages.$COLOR_RST"
    install_packages
    echo -e "$COLOR_CYAN_BOLD[*] Installing Snap + packages.$COLOR_RST"
    install_snapd
    echo -e "$COLOR_CYAN_BOLD[*] Installing Jekyll.$COLOR_RST"
    install_jekyll
    echo -e "$COLOR_CYAN_BOLD[*] Configuring aliases.$COLOR_RST"
    configure_aliases
    echo -e "$COLOR_CYAN_BOLD[*] Configuring Terminator.$COLOR_RST"
    configure_terminator
    echo -e "$COLOR_CYAN_BOLD[*] Configuring Samba share.$COLOR_RST"
    configure_smb_share
    echo -e "$COLOR_CYAN_BOLD[*] Configuring Metasploit.$COLOR_RST"
    configure_metasploit
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc web tools.$COLOR_RST"
    install_web_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc recon tools.$COLOR_RST"
    install_recon_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc AD tools.$COLOR_RST"
    install_ad_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc exploit tools.$COLOR_RST"
    install_exploit_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc post exploit tools.$COLOR_RST"
    install_post_exploit_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc privesc tools.$COLOR_RST"
    install_privesc_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc pivot tools.$COLOR_RST"
    install_pivot_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc Windows tools.$COLOR_RST"
    install_windows_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc network tools.$COLOR_RST"
    install_network_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc AV bypass tools.$COLOR_RST"
    install_av_bypass_tools
    echo -e "$COLOR_CYAN_BOLD[*] Downloading misc tools.$COLOR_RST"
    install_misc_tools
    echo -e "$COLOR_CYAN_BOLD[*] Updating filesystem DB.$COLOR_RST"
    updatedb
    echo -e "$COLOR_CYAN_BOLD[*] Populating pub tools directory.$COLOR_RST"
    populate_pub_tools
    echo -e "$COLOR_CYAN_BOLD[*] Saving update script.$COLOR_RST"
    save_custom_scripts
    
    which xfconf-query >/dev/null
    if [ $? == 0 ];
    then
        echo -e "$COLOR_CYAN_BOLD[*] Setting XFCE custom settings.$COLOR_RST"
        set_xfce_custom_settings
    fi
}

# Check if current user is root
if [ ! $(id --u) == 0 ];
then
    echo "You must be root"
    exit
fi

full_install

