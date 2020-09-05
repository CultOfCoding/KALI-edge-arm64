#!/usr/bin/env python3

import gzip
import json
import os
import shutil
import time
from pathlib import Path

import dns.resolver
import geoip2.database
import requests
from folium import Map, Marker, Popup

from core.utils import DOMAIN, Helpers, logger

helpers = Helpers()

# Working program directories
prog_root = Path(os.path.dirname(os.path.dirname(__file__)))
geomap_root = prog_root / 'geomap'

# Create the geomap directory
if not os.path.exists(geomap_root):
    os.mkdir(geomap_root)

# Working files
gl_zipped = geomap_root / 'GeoLite2-City.mmdb.gz'
gl_file = geomap_root / 'GeoLite2-City.mmdb'
ip_map_file = os.path.join(geomap_root, 'ip_map.html')
url = 'https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz'


def geo_query_map(QRY):
    # Check if Geolite file exists
    geolite_check()

    # Used to resolve domains to ip address
    resolver = dns.resolver.Resolver()
    resolver.nameservers = ['64.6.64.6',
                            '64.6.65.6',
                            '84.200.69.80',
                            '84.200.70.40']
    if DOMAIN.findall(QRY):
        try:
            response = resolver.query(QRY, 'A')
            QRY = response.rrset[-1]
            map_maxmind(str(QRY))
        except dns.resolver.NoAnswer as err:
            logger.error(f"[error] {err}")
        except Exception as err:
            logger.warning(err)
    else:
        map_maxmind(QRY)


# ---[ GeoLite File Check/Download ]-------------------------------
def geolite_check():
    if os.path.exists(gl_zipped):
        print(f"{gl_zipped} exists, unzipping...")
        with gzip.open(gl_zipped, 'rb') as f_in:
            with open(gl_file, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
            os.remove(gl_zipped)

    if not os.path.exists(gl_file):
        print("-" * 80)
        logger.warning(f"[-] {gl_file} does not exist.")
        geoip_download = input("\n[+] Would you like to download the GeoLite2-City file (yes/no)? ")
        if geoip_download.lower() == 'yes':
            os.chdir(geomap_root)
            helpers.download_file(url)
            with gzip.open(gl_zipped, 'rb') as f_in:
                with open(gl_file, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            os.remove(gl_zipped)


# ---[ Geolocate and Map IP Address ]-------------------------------
# Ref: https://github.com/maxmind/GeoIP2-python
def map_maxmind(QRY):
    try:
        geo_reader = geoip2.database.Reader(gl_file)
        ip_map = Map([40, -5], tiles='OpenStreetMap', zoom_start=3)
        response = geo_reader.city(QRY)
        if response.location:
            lat = response.location.latitude
            lon = response.location.longitude
            popup = Popup(QRY)

            Marker([lat, lon], popup=popup).add_to(ip_map)
            ip_map.save(ip_map_file)
    except geoip2.errors.AddressNotFoundError:
        logger.warning(f"[-] Address {QRY} is not in the geoip database.")
    except FileNotFoundError:
        logger.info(f"\n[*] Please download the GeoLite2-City database file: ")
        print("    --> https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz")
        time.sleep(2)


def map_free_geo(QRY):
    ip_map = Map([40, -5], tiles='OpenStreetMap', zoom_start=3)
    try:
        response = f'https://freegeoip.live/json/{QRY}'
        req = requests.get(response)
        if req.status_code == 200:
            data = json.loads(req.content.decode('utf-8'))
            lat = data['latitude']
            lon = data['longitude']
            popup = Popup(QRY)

            Marker([lat, lon], popup=popup).add_to(ip_map)
            ip_map.save(ip_map_file)
        else:
            req.raise_for_status()
    except Exception as err:
        logger.warning(f"[error] {err}\n")


def multi_map(input_file):
    os.chdir(geomap_root)
    # Check if Geolite file exists
    geolite_check()

    file_path = os.path.abspath(os.pardir)
    input_file = f"{file_path}/{input_file}"
    with open(input_file) as f:
        line = [line.strip() for line in f.readlines()]
        ip_map = Map([40, -5], tiles='OpenStreetMap', zoom_start=3)
        try:
            geo_reader = geoip2.database.Reader('GeoLite2-City.mmdb')
            for addr in line:
                response = geo_reader.city(addr)
                if response.location:
                    logger.success(f"[+] Mapping {addr}")
                    lat = response.location.latitude
                    lon = response.location.longitude
                    popup = Popup(addr)

                    Marker([lat, lon], popup=popup).add_to(ip_map)
                    ip_map.save('multi_map.html')
        except ValueError as err:
            print(f'[error] {err}')
        except geoip2.errors.AddressNotFoundError:
            logger.warning(f"[-] Address {addr} is not in the geoip database.")
        except FileNotFoundError:
            geolite_check()
