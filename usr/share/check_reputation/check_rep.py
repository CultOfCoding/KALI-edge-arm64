#!/usr/bin/env python3

__author__ = "DFIRSec (@pulsecode)"
__version__ = "2.0"
__description__ = "Check IP or Domain reputation against 400+ open-source Blacklists."

# TODO: Include additional VirusTotal functions

import argparse
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

import colored
from colorama import Back, Fore, Style, init
from ruamel.yaml import YAML

from core.geomap import *
from core.utils import DOMAIN, URL, EMAIL, IP, NET, Workers, logger
from core.vt_check import VirusTotalChk

# Check python version is v3.6+
if sys.version_info[0] == 3 and sys.version_info[1] <= 5:
    print('\n[x] Please use python version 3.6 or higher.\n')
    sys.exit()

# Initialize Colorama
init(autoreset=True)

# Define program root directory
prog_root = Path(__file__).resolve().parent

# ---[ Configuration Parser ]-------------------------------
yaml = YAML()
settings = prog_root.joinpath('settings.yml')
with open(settings) as _file:
    config = yaml.load(_file)


def main():
    banner = '''
   ________              __      ____
  / ____/ /_  ___  _____/ /__   / __ \___  ____
 / /   / __ \/ _ \/ ___/ //_/  / /_/ / _ \/ __ \ 
/ /___/ / / /  __/ /__/ ,<    / _, _/  __/ /_/ /
\____/_/ /_/\___/\___/_/|_|  /_/ |_|\___/ .___/
                                       /_/
'''

    print(Fore.CYAN + banner + Style.RESET_ALL)
    print("Check IP and Domain Reputation")

    parser = argparse.ArgumentParser(
        description='Check IP or Domain Reputation',
        formatter_class=argparse.RawTextHelpFormatter,
        epilog='''
    Options
    --------------------
    freegeoip [freegeoip.live]  - free/opensource geolocation service     
    virustotal [virustotal.com] - online multi-antivirus scan engine            
    
    * NOTE: 
    Use of the VirusTotal option requires an API key.  
    The service is "free" to use, however you must register 
    for an account to receive an API key.''')

    optional = parser._action_groups.pop()
    required = parser.add_argument_group('required arguments')
    required.add_argument('query', help='query ip address or domain')
    optional.add_argument('--log', action='store_true', help='log results to file')
    optional.add_argument('--vt', action='store_true', help='check virustotal')

    group = optional.add_mutually_exclusive_group()
    group.add_argument('--fg', action='store_true', help='use freegeoip for geolocation')  # nopep8
    group.add_argument('--mx', nargs='+', metavar='FILE', help='geolocate multiple ip addresses or domains')  # nopep8

    parser._action_groups.append(optional)
    args = parser.parse_args()
    QRY = args.query

    if len(sys.argv[1:]) == 0:
        parser.print_help()
        parser.exit()

    # Initialize utilities
    workers = Workers(QRY)

    print("\n" + Fore.GREEN + "[+] Running checks..." + Style.RESET_ALL)

    if args.log:
        if not os.path.exists('logfile'):
            os.mkdir('logfile')
        dt_stamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        file_log = logging.FileHandler(f"logfile/logfile_{dt_stamp}.txt")
        file_log.setFormatter(logging.Formatter("[%(asctime)s %(levelname)s] %(message)s",
                                                 datefmt="%m/%d/%Y %I:%M:%S"))  # nopep8
        logger.addHandler(file_log)

    if args.fg:
        map_free_geo(QRY)

    if args.mx:
        print(colored.stylize("\n--[ Processing Geolocation Map ]--", colored.attr("bold")))  # nopep8
        multi_map(input_file=args.mx[0])
        print(colored.stylize("\n--[ GeoIP Map File ]--", colored.attr("bold")))  # nopep8
        try:
            multi_map_file = Path('multi_map.html').resolve(strict=True)
        except FileNotFoundError:
            logger.info("[-] Geolocation map file was not created or does not exist.")  # nopep8
        else:
            logger.info(f"[>] Geolocation map file saved to: {multi_map_file}")
        sys.exit(1)

    if args.vt:
        print(colored.stylize("\n--[ VirusTotal Detections ]--", colored.attr("bold")))  # nopep8
        if not config['VIRUS-TOTAL']['api_key']:
            logger.warning("Please add VirusTotal API key to the 'settings.yml' file, or add it below")  # nopep8
            user_vt_key = input("Enter key: ")
            config['VIRUS-TOTAL']['api_key'] = user_vt_key

            with open('settings.yml', 'w') as output:
                yaml.dump(config, output)

        api_key = config['VIRUS-TOTAL']['api_key']
        virustotal = VirusTotalChk(api_key)
        if DOMAIN.findall(QRY):
            virustotal.vt_run('domains', QRY)
        elif IP.findall(QRY):
            virustotal.vt_run('ip_addresses', QRY)
        elif URL.findall(QRY):
            virustotal.vt_run('urls', QRY)
        else:
            virustotal.vt_run('files', QRY)
            print(colored.stylize("\n--[ Team Cymru Detection ]--", colored.attr("bold")))  # nopep8
            workers.tc_query(qry=QRY)
            sys.exit("\n")

    if DOMAIN.findall(QRY) and not EMAIL.findall(QRY):
        print(colored.stylize("\n--[ Querying Domain Blacklists ]--", colored.attr("bold")))  # nopep8
        workers.spamhaus_dbl_worker()
        workers.blacklist_dbl_worker()
        print(colored.stylize(f"\n--[ WHOIS for {QRY} ]--", colored.attr("bold")))  # nopep8
        workers.whois_query(QRY)

    elif IP.findall(QRY):
        # Check if cloudflare ip
        print(colored.stylize("\n--[ Using Cloudflare? ]--", colored.attr("bold")))  # nopep8
        if workers.cflare_results(QRY):
            logger.info("Cloudflare IP: Yes")
        else:
            logger.info("Cloudflare IP: No")

        print(colored.stylize("\n--[ Querying DNSBL Lists ]--", colored.attr("bold")))  # nopep8
        workers.dnsbl_mapper()
        workers.spamhaus_ipbl_worker()
        print(colored.stylize("\n--[ Querying IP Blacklists ]--", colored.attr("bold")))  # nopep8
        workers.blacklist_ipbl_worker()

    elif NET.findall(QRY):
        print(colored.stylize("\n--[ Querying NetBlock Blacklists ]--", colored.attr("bold")))  # nopep8
        workers.blacklist_netblock_worker()

    else:
        print(Fore.YELLOW + "[!] Please enter a valid query -- Domain or IP address" + Style.RESET_ALL)  # nopep8
        print("=" * 60, "\n")
        parser.print_help()
        parser.exit()

    # ---[ Results output ]-------------------------------
    print(colored.stylize("\n--[ Results ]--", colored.attr("bold")))
    TOTALS = workers.DNSBL_MATCHES + workers.BL_MATCHES
    BL_TOTALS = workers.BL_MATCHES
    if TOTALS == 0:
        logger.info(f"[-] {QRY} is not listed in any Blacklists\n")
    else:
        _QRY = Fore.YELLOW + QRY + Style.BRIGHT + Style.RESET_ALL
        _DNSBL_MATCHES = Fore.WHITE + Back.RED + str(workers.DNSBL_MATCHES) + Style.BRIGHT + Style.RESET_ALL  # nopep8
        _BL_TOTALS = Fore.WHITE + Back.RED + str(BL_TOTALS) + Style.BRIGHT + Style.RESET_ALL  # nopep8
        logger.info(f"[>] {_QRY} is listed in {_DNSBL_MATCHES} DNSBL lists and {_BL_TOTALS} Blacklists\n")  # nopep8

    # ---[ Geo Map output ]-------------------------------
    if args.fg or args.mx:
        print(colored.stylize("--[ GeoIP Map File ]--", colored.attr("bold")))  # nopep8
        time_format = "%d %B %Y %H:%M:%S"
        try:
            ip_map_file = prog_root.joinpath('geomap/ip_map.html').resolve(strict=True)  # nopep8
        except FileNotFoundError:
            logger.warning("[-] Geolocation map file was not created/does not exist.\n")  # nopep8
        else:
            ip_map_timestamp = datetime.fromtimestamp(os.path.getctime(ip_map_file))  # nopep8
            logger.info(f"[>] Geolocation map file created: {ip_map_file} [{ip_map_timestamp.strftime(time_format)}]\n")  # nopep8


if __name__ == "__main__":
    main()
