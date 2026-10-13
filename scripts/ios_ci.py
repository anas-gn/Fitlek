"""Validate Apple credentials, select a fresh build number, and prepare CI files."""
import argparse
import base64
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, rsa
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

BUNDLE_ID = "com.sirvya.app"
REQUIRED = (
    "APP_STORE_CONNECT_KEY_ID", "APP_STORE_CONNECT_ISSUER_ID",
    "APP_STORE_CONNECT_PRIVATE_KEY_BASE64", "IOS_CERTIFICATE_PRIVATE_KEY",
)


def credentials():
    missing = [name for name in REQUIRED if not os.environ.get(name, "").strip()]
    if missing:
        raise ValueError("Missing GitHub Actions secrets: " + ", ".join(missing))
    key_id = os.environ[REQUIRED[0]].strip()
    if not re.fullmatch(r"[A-Z0-9]{10}", key_id):
        raise ValueError("App Store Connect Key ID must contain 10 letters/numbers.")
    issuer = str(uuid.UUID(os.environ[REQUIRED[1]].strip()))
    try:
        pem = base64.b64decode("".join(os.environ[REQUIRED[2]].split()), validate=True)
        apple_key = serialization.load_pem_private_key(pem, password=None)
        certificate_pem = os.environ[REQUIRED[3]].encode()
        certificate_key = serialization.load_pem_private_key(certificate_pem, password=None)
    except (ValueError, TypeError) as error:
        raise ValueError("The Apple API key or distribution signing key is invalid.") from error
    if not isinstance(apple_key, ec.EllipticCurvePrivateKey) or not isinstance(apple_key.curve, ec.SECP256R1):
        raise ValueError("The App Store Connect API key must be an ES256 .p8 key.")
    if not isinstance(certificate_key, rsa.RSAPrivateKey) or certificate_key.key_size < 2048:
        raise ValueError("Distribution signing requires an RSA key of at least 2048 bits.")
    return key_id, issuer, pem, apple_key, certificate_pem


def apple_token(key_id, issuer, private_key):
    def encode(value):
        return base64.urlsafe_b64encode(value).rstrip(b"=")
    now = int(time.time())
    header = encode(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    payload = encode(json.dumps({"iss": issuer, "iat": now, "exp": now + 600,
                                 "aud": "appstoreconnect-v1"}).encode())
    message = header + b"." + payload
    r, s = decode_dss_signature(private_key.sign(message, ec.ECDSA(hashes.SHA256())))
    return (message + b"." + encode(r.to_bytes(32, "big") + s.to_bytes(32, "big"))).decode()


def apple_get(token, resource, **parameters):
    url = "https://api.appstoreconnect.apple.com/v1/" + resource
    if parameters:
        url += "?" + urllib.parse.urlencode(parameters)
    request = urllib.request.Request(url, headers={"Authorization": "Bearer " + token})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)["data"]
    except urllib.error.HTTPError as error:
        raise ValueError(f"Apple API returned HTTP {error.code} for {resource}. Check the API key's access to Sirvya and signing resources.") from error


def next_build_number(versions, minimum, requested=""):
    # A new integer major is higher than a previous dotted CFBundleVersion too.
    majors = [int(v.split(".")[0]) for v in versions if re.fullmatch(r"\d+(?:\.\d+){0,2}", v)]
    latest = max(majors, default=0)
    candidate = max(minimum, latest + 1)
    if requested.strip():
        if not re.fullmatch(r"[1-9]\d*", requested.strip()):
            raise ValueError("Build number must be a positive integer.")
        candidate = int(requested)
        if candidate <= latest or candidate < minimum:
            raise ValueError("Choose a build number higher than Apple's existing builds and at least the pubspec build number.")
    if candidate > 9999:
        raise ValueError("Automatic build numbering exceeded 9999. Configure an appropriate dotted CFBundleVersion before continuing.")
    return candidate


def preflight():
    key_id, issuer, _, key, _ = credentials()
    token = apple_token(key_id, issuer, key)
    apps = apple_get(token, "apps", **{"filter[bundleId]": BUNDLE_ID, "limit": 1})
    if len(apps) != 1:
        raise ValueError("This key cannot find com.sirvya.app in App Store Connect.")
    app_id = apps[0]["id"]
    apple_get(token, "certificates", limit=1)
    apple_get(token, "profiles", limit=1)
    # Fetch all pages so earlier uploads cannot cause duplicate build numbers.
    builds = apple_get(token, "builds", **{"filter[app]": app_id, "sort": "-uploadedDate", "limit": 200})
    if len(builds) == 200:
        raise ValueError("More than 200 existing builds: extend build-number pagination before building.")
    version = re.search(r"^version:\s*[^+\s]+\+(\d+)\s*$", Path("pubspec.yaml").read_text(), re.MULTILINE)
    if not version:
        raise ValueError("pubspec.yaml needs a version with a numeric build suffix.")
    number = next_build_number([b["attributes"]["version"] for b in builds], int(version[1]), os.environ.get("REQUESTED_BUILD_NUMBER", ""))
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
            output.write(f"app_id={app_id}\nbuild_number={number}\n")
    print(f"Apple credentials verified for {BUNDLE_ID}; next build: {number}.")


def prepare():
    key_id, issuer, pem, _, certificate_pem = credentials()
    directory = Path(os.environ["RUNNER_TEMP"]) / "sirvya-ios-signing"
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    directory.chmod(0o700)
    files = {"api-key.p8": pem, "distribution-key.pem": certificate_pem}
    for name, content in files.items():
        path = directory / name
        path.write_bytes(content)
        path.chmod(0o600)
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as output:
        output.write(f"APP_STORE_CONNECT_KEY_IDENTIFIER={key_id}\n")
        output.write(f"APP_STORE_CONNECT_ISSUER_ID={issuer}\n")
        output.write(f"APP_STORE_CONNECT_PRIVATE_KEY=@file:{directory / 'api-key.p8'}\n")
        output.write(f"CERTIFICATE_PRIVATE_KEY=@file:{directory / 'distribution-key.pem'}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["preflight", "prepare"])
    arguments = parser.parse_args()
    try:
        {"preflight": preflight, "prepare": prepare}[arguments.command]()
    except (ValueError, OSError, urllib.error.URLError) as error:
        print(f"::error::{error}", file=sys.stderr)
        sys.exit(1)
