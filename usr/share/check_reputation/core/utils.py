#!/usr/bin/env python3

import logging
import pathlib
import random
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from http.client import responses
from ipaddress import AddressValueError, IPv4Address, IPv4Network

import colored
import coloredlogs
import dns.resolver
import requests
import verboselogs
import whois
from tqdm import tqdm

from core.feeds import *

logger = verboselogs.VerboseLogger(__name__)
logger.setLevel(logging.INFO)
coloredlogs.install(level=None, logger=logger, fmt='%(message)s',
                    level_styles={
                        'notice': {'color': 'black', 'bright': True},
                        'warning': {'color': 'yellow'},
                        'success': {'color': 'green', 'bold': True},
                        'error': {'color': 'red'}
                    })


class Helpers(object):
    # ---[ Regex Parser ]-------------------------------
    @staticmethod
    def regex(_type):
        # ref: http://data.iana.org/TLD/tlds-alpha-by-domain.txt
        dir_path = pathlib.Path(__file__).parent
        with open(dir_path/'tlds.txt', 'r') as f:
            tlds = f.read()
        pattern = dict(
            ip_addr=r"(^(\d{1,3}\.){0,3}\d{1,3}$)",
            ip_net=r"(^(\d{1,3}\.){0,3}\d{1,3}/\d{1,2}$)",
            domain=r"([A-Za-z0-9]+(?:[\-|\.][A-Za-z0-9]+)*(?:\[\.\]|\.)(?:{}))".format(tlds),
            email=r"(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]{2,5}$)",
            url=r"(http[s]?:\/\/(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+)",
            md5=r"(^[a-z0-9]{32}$)",
            sha1=r"(^[a-z0-9]{40}$)",
            sha224=r"(^[a-z0-9]{56}$))",
            sha256=r"(^[a-z0-9]{64}$)",
            sha512=r"(^[a-z0-9]{128}$)",
            base64=r"(^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4})$)"
            # option: base64=r"(^[-A-Za-z0-9+/=]{3,}$)"
        )
        try:
            pattern = re.compile(pattern[_type])
        except re.error:
            print("[!] Invalid input specified.")
            sys.exit(0)
        return pattern

    # ---[ Common User-Agents ]-------------------------------
    @staticmethod
    def headers():
        ua_list = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 "
            "Safari/537.36 Edge/12.246",
            "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:40.0) Gecko/20100101 Firefox/43.0",
            "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 "
            "Safari/537.36",
            "Mozilla/5.0 (X11; Linux i686; rv:30.0) Gecko/20100101 Firefox/42.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/40.0.2214.38 Safari/537.36",
            "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)"
        ]
        use_headers = {
            'user-agent': random.choice(ua_list)
        }
        return use_headers

    # ---[ File Downloader NO LONGER USED]-------------------------------
    @staticmethod
    def download_file(url):
        local_file = url.split('/')[-1]
        try:
            req = requests.get(url, local_file, stream=True)
            chunk_size = 1024
            size = int(req.headers['content-length'])
            if req.status_code == 403:
                logger.info(responses[403])
                sys.exit()
            elif req.status_code == 200:
                with open(local_file, 'wb') as f:
                    for data in tqdm(iterable=req.iter_content(chunk_size=chunk_size),
                                     ncols=100, total=size / chunk_size, unit='KB'):
                        f.write(data)
            else:
                logger.info((req.status_code, responses[req.status_code]))
                sys.exit()
        except requests.exceptions.Timeout:
            logger.notice(f"[timeout] {url}")
        except requests.exceptions.HTTPError as err:
            logger.error(f"[error] {err}")
        except requests.exceptions.ConnectionError as err:
            logger.error(f"[error] {err}")
        except requests.exceptions.RequestException as err:
            logger.critical(f"[critical] {err}")


# ---[ Helper objects ]-------------------------------
helpers = Helpers()
IP = helpers.regex(_type='ip_addr')
NET = helpers.regex(_type='ip_net')
DOMAIN = helpers.regex(_type='domain')
URL = helpers.regex(_type='url')
EMAIL = helpers.regex(_type='email')


class Workers(object):
    def __init__(self, QRY):
        self.query = QRY
        self.DNSBL_MATCHES = 0
        self.BL_MATCHES = 0

    # ---[ Query DNSBL Lists ]-------------------------------
    # Ref: https://stackoverflow.com/questions/24093888/python-asynchronous-reverse-dns-lookups
    def dnsbl_query(self, blacklist):
        try:
            resolver = dns.resolver.Resolver()
            # VeriSign and DNS.WATCH DNS servers (no logging)
            resolver.nameservers = ['64.6.64.6',
                                    '64.6.65.6',
                                    '84.200.69.80',
                                    '84.200.70.40']
            resolver.timeout = 3
            resolver.lifetime = 3
            qry = ''
            if helpers.regex(_type='ip_addr').findall(self.query):
                qry = '.'.join(reversed(str(self.query).split("."))) + "." + blacklist  # nopep8
            elif helpers.regex(_type='domain').findall(self.query):
                qry = '.'.join(str(self.query).split(".")) + "." + blacklist
            answers = resolver.query(qry, "A")
            answer_txt = resolver.query(qry, 'TXT')
            logger.success(f"> {self.query} --> {blacklist} {answers[0]} {answer_txt[0]}")  # nopep8
            self.DNSBL_MATCHES += 1
        except (dns.resolver.NXDOMAIN,
                dns.resolver.Timeout,
                dns.resolver.NoNameservers,
                dns.resolver.NoAnswer):
            pass

    def dnsbl_mapper(self):
        with ThreadPoolExecutor(max_workers=50) as executor:
            dnsbl_map = {executor.submit(
                self.dnsbl_query, url): url for url in DNSBL_LISTS}
            for future in as_completed(dnsbl_map):
                try:
                    future.result()
                    dnsbl_map[future]
                except Exception as exc:
                    logger.error(f"{dnsbl_map[future]} generated an exception: {exc}")  # nopep8

    def spamhaus_ipbl_worker(self):
        try:
            self.dnsbl_query(SPAMHAUS_IP)
        except Exception as exc:
            logger.error(exc)

    def spamhaus_dbl_worker(self):
        try:
            self.dnsbl_query(SPAMHAUS_DOM)
        except Exception as exc:
            logger.error(exc)

    # ---[ Query Blacklists ]-------------------------------
    def bl_mapper(self, query_type, list_type, list_name):
       with ThreadPoolExecutor(max_workers=50) as executor:
           mapper = {executor.submit(query_type, url): url for url in list_type}  # nopep8
           for future in as_completed(mapper):
               try:
                   future.result()
                   mapper[future]
               except Exception as exc:
                   logger.error(f"{mapper[future]} generated an exception: {exc}")  # nopep8
           if self.BL_MATCHES == 0:
               logger.info(f"[-] {self.query} is not listed in active {list_name}")  # nopep8

    def blacklist_worker(self, blacklist):
        try:
            req = requests.get(blacklist, headers=helpers.headers(), timeout=3)
            req.encoding = 'utf-8'
            match = re.findall(self.query, req.text)
            if match:
                logger.success(f"\u2714 {self.query} --> {blacklist}")
                self.BL_MATCHES += 1
        except AddressValueError as err:
            logger.error(f"[error] {err}")
        except requests.exceptions.Timeout:
            logger.notice(f"[timeout] {blacklist}")
        except requests.exceptions.HTTPError as err:
            logger.error(f"[error] {err}")
        except requests.exceptions.ConnectionError:
            logger.error(f"[error] Problem connecting to {blacklist}")
        except requests.exceptions.RequestException as err:
            logger.critical(f"[critical] {err}")

    def blacklist_query(self, blacklist):
        self.blacklist_worker(blacklist)

    def blacklist_dbl_worker(self):
        self.bl_mapper(query_type=self.blacklist_query,
                       list_type=DOM_LISTS,
                       list_name='Domain Blacklists')

    def blacklist_ipbl_worker(self):
        self.bl_mapper(query_type=self.blacklist_query,
                       list_type=IP_LISTS,
                       list_name='IP Blacklists')

    # ----[ IP BLOCKS SECTION ]-------------------------------
    def blacklist_ipblock_query(self, blacklist):
        self.blacklist_worker(blacklist)

    def blacklist_netblock_worker(self):
        self.bl_mapper(query_type=self.blacklist_ipblock_query,
                       list_type=IP_BLOCKS,
                       list_name='NetBlock Blacklists')

    # ----[ WHOIS SECTION ]-------------------------------
    def whois_query(self, QRY):
        try:
            dns_resp = [rdata for rdata in dns.resolver.query(QRY, 'A')]
            print(f"IP Address: {dns_resp[0]}")

            # Check if cloudflare ip
            if self.cflare_results(dns_resp[0]):
                logger.info("Cloudflare IP: Yes")
            else:
                logger.info("Cloudflare IP: No")

            w = whois.whois(QRY)
            if w.registered:
                print("Registered to:", w.registered)

            print("Registrar:", w.registrar)
            print("Organization:", w.org)

            if isinstance(w.updated_date, list):
                print("Updated:", ", ".join(str(x)for x in w.updated_date))
            else:
                print("Updated:", w.updated_date)

            if isinstance(w.creation_date, list):
                print("Created:", ", ".join(str(x)for x in w.creation_date))
            else:
                print("Created:", w.creation_date)

            if isinstance(w.expiration_date, list):
                print("Expires:", ", ".join(str(x)for x in w.expiration_date))
            else:
                print("Expires:", w.expiration_date)

            if isinstance(w.emails, list):
                print("Email Address:", ", ".join(x for x in w.emails))
            else:
                print("Email Address:", w.emails)

        except Exception as exc:
            print(f"[-] Domain {QRY} does not appear to be registered domain.\n {exc}")  # nopep8
            time.sleep(1)  # prevents [WinError 10054]

    # ----[ CLOUDFLARE CHECK SECTION ]-------------------------------
    @staticmethod
    def chk_cflare_list(QRY):
        for net in CFLARE_IPS:
            if IPv4Address(QRY) in IPv4Network(net):
                yield True

    def cflare_results(self, QRY):
        for ip in self.chk_cflare_list(QRY):
            return ip

    def tc_query(self, qry):
        try:
            cymru = f"{qry}.malware.hash.cymru.com"
            resolver = dns.resolver.Resolver()
            resolver.timeout = 1
            resolver.lifetime = 1
            answers = resolver.query(cymru, "A")
            logger.error(f"\u2718 malware.hash.cymru.com: MALICIOUS")
        except dns.resolver.NXDOMAIN:
            logger.notice(f"\u2718 malware.hash.cymru.com: Not Found")
        except dns.resolver.Timeout:
            logger.notice(f"[timeout] malware.hash.cymru.com")
        except dns.resolver.NoNameservers:
            logger.warning(f"[no name servers] malware.hash.cymru.com")
        except dns.resolver.NoAnswer:
            logger.error(f"[no answer] malware.hash.cymru.com")
