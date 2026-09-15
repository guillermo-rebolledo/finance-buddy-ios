#!/usr/bin/env python3
"""Check Release settings and a built bundle (optional second argument)."""
import json
import pathlib
import plistlib
import sys

settings = next(target['buildSettings'] for target in json.load(open(sys.argv[1]))
                if target['target'] == 'FinanceBuddy')
bundle = (pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else
          pathlib.Path(settings['TARGET_BUILD_DIR']) / settings['WRAPPER_NAME'])
info = plistlib.loads((bundle / 'Info.plist').read_bytes())

def require(condition, name):
    if not condition:
        sys.exit('Release check failed: ' + name)

require(settings['TARGETED_DEVICE_FAMILY'] == '1' and info.get('UIDeviceFamily') == [1],
        'TARGETED_DEVICE_FAMILY must be iPhone only (1)')
require(info.get('API_BASE_URL') == 'https://financebuddy.tech',
        'API_BASE_URL must be the production HTTPS origin')
require('NSAppTransportSecurity' not in info, 'NSAppTransportSecurity must not add Release exceptions')
require(info.get('CFBundleIdentifier') == 'com.guillermorebolledo.FinanceBuddy',
        'CFBundleIdentifier must match the registered App ID')
require(info.get('CFBundleVersion') == settings['CURRENT_PROJECT_VERSION'],
        'CFBundleVersion must match CURRENT_PROJECT_VERSION')
require(info.get('CFBundleShortVersionString') == settings['MARKETING_VERSION'],
        'CFBundleShortVersionString must match MARKETING_VERSION')
for key, value in [('GIDClientID', info.get('GIDClientID')),
                   ('GIDServerClientID', info.get('GIDServerClientID')),
                   ('GOOGLE_REVERSED_CLIENT_ID', settings.get('GOOGLE_REVERSED_CLIENT_ID'))]:
    require(isinstance(value, str) and value and not any(
        placeholder in value.lower() for placeholder in ('configure', 'placeholder', 'your-', '$(')), key)
require(settings['GOOGLE_REVERSED_CLIENT_ID'] in [scheme
        for item in info.get('CFBundleURLTypes', []) for scheme in item.get('CFBundleURLSchemes', [])],
        'GOOGLE_REVERSED_CLIENT_ID URL scheme')
require(info.get('ITSAppUsesNonExemptEncryption') is False, 'ITSAppUsesNonExemptEncryption must be false')
require((bundle / 'PrivacyInfo.xcprivacy').is_file(), 'PrivacyInfo.xcprivacy must be in app bundle')
print('Release configuration checks passed.')
