#!/usr/bin/env python3

import json
import sys
from http.client import responses

import colored
import requests
import simplejson

from core.utils import Helpers, logger

helpers = Helpers()


class VirusTotalChk(object):
    # Ref: https://developers.virustotal.com/v3.0/reference

    def __init__(self, api_key=None):
        self.api_key = api_key
        self.base_url = 'https://virustotal.com/api/v3'
        self.headers = {'x-apikey': self.api_key,
                        'Accept': 'application/json'}

        if api_key is None:
            raise Exception("Verify that you have provided your API key.")

    # ---[ VirusTotal Connection ]-------------------------------
    def vt_connect(self, url):
        try:
            resp = requests.get(url, headers=self.headers, timeout=5)
            resp.encoding = 'utf-8'
            if resp.status_code == 401:
                print("[error] Verify that you have provided a valid API key.")
                sys.exit()
            if resp.status_code != 200:
                print(f"[error] {resp.status_code} {responses[resp.status_code]}")
            else:
                return resp.json()
        except requests.exceptions.Timeout:
            logger.warning(f"[timeout] {url}")
        except requests.exceptions.HTTPError as err:
            logger.error(f"[error] {err}")
        except requests.exceptions.ConnectionError as err:
            logger.error(f"[error] {err}")
        except requests.exceptions.RequestException as err:
            logger.critical(f"[critical] {err}")

    def vt_run(self, scan_type, QRY):
        url = f"{self.base_url}/{scan_type}/{QRY}"
        data = json.dumps(self.vt_connect(url))
        json_resp = json.loads(data)
        if json_resp:
            good = 0
            bad = 0
            results = json_resp['data']['attributes']
            try:
                if results['meaningful_name']:
                    logger.info("Filename: ", results['meaningful_name'])
            except:
                pass
            for engine, result in results['last_analysis_results'].items():
                if result['category'] == 'malicious':
                    bad += 1
                    logger.error(f"\u2718 {engine}: {result['category'].upper()}")
                else:
                    good += 1
            if bad == 0:
                logger.success(f"\u2714 {good} engines deemed '{QRY}' as harmless\n")
            else:
                logger.info(f"{bad} engines deemed '{QRY}' as malicious\n")
