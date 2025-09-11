#!/usr/bin/env python3

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def log(message):
    """Log message to stdout with timestamp"""
    print(f"[tailscale-disable-key-expiry] {message}")


def read_secret_file(filepath):
    """Read content from a secret file"""
    try:
        with open(filepath, "r") as f:
            content = f.read().strip()
        if not content:
            raise ValueError(f"Secret file {filepath} is empty")
        return content
    except FileNotFoundError:
        raise FileNotFoundError(f"Secret file not found: {filepath}")
    except PermissionError:
        raise PermissionError(f"Cannot read secret file: {filepath}")


def get_oauth_token(client_id, client_secret):
    """Get OAuth token from Tailscale API"""
    log("Requesting OAuth token from Tailscale API...")

    data = urllib.parse.urlencode(
        {"client_id": client_id, "client_secret": client_secret}
    ).encode("utf-8")

    req = urllib.request.Request(
        "https://api.tailscale.com/api/v2/oauth/token", data=data, method="POST"
    )

    try:
        with urllib.request.urlopen(req) as response:
            response_data = response.read().decode("utf-8")

        if not response_data:
            raise ValueError("Empty response from OAuth API")

        oauth_response = json.loads(response_data)
        token = oauth_response.get("access_token")

        if not token or token == "null":
            log(f"ERROR: Failed to obtain OAuth token for key expiry disable")
            log(f"OAuth response: {response_data}")
            return None

        log("Successfully obtained OAuth token")
        return token

    except urllib.error.URLError as e:
        log(f"ERROR: Failed to connect to OAuth API: {e}")
        return None
    except json.JSONDecodeError as e:
        log(f"ERROR: Invalid JSON response from OAuth API: {e}")
        return None


def find_device_by_hostname(token, tailnet_org, hostname):
    """Find device by exact hostname match"""
    req = urllib.request.Request(
        f"https://api.tailscale.com/api/v2/tailnet/{tailnet_org}/devices",
        headers={"Authorization": f"Bearer {token}"},
    )

    try:
        with urllib.request.urlopen(req) as response:
            response_data = response.read().decode("utf-8")

        devices_response = json.loads(response_data)
        devices = devices_response.get("devices", [])

        for device in devices:
            if device.get("hostname") == hostname:
                return device["nodeId"]

        return None

    except urllib.error.URLError as e:
        log(f"ERROR: Failed to fetch devices: {e}")
        return None
    except json.JSONDecodeError as e:
        log(f"ERROR: Invalid JSON response from devices API: {e}")
        return None


def disable_key_expiry(token, device_id):
    """Disable key expiry for a device"""
    log(f"Disabling key expiry for device {device_id}")

    # Prepare JSON payload
    payload = {"keyExpiryDisabled": True}
    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        f"https://api.tailscale.com/api/v2/device/{device_id}/key",
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as response:
            response.read()  # Consume response
        log(f"Key expiry disabled for device {device_id}")
        return True
    except urllib.error.URLError as e:
        log(f"ERROR: Failed to disable key expiry for device {device_id}: {e}")
        return False


def wait_for_device(token, tailnet_org, hostname, max_attempts=12, delay=5):
    """Wait for device to appear in the tailnet with retries"""
    log(f"Waiting for device with hostname {hostname} to appear in tailnet...")

    for attempt in range(1, max_attempts + 1):
        device_id = find_device_by_hostname(token, tailnet_org, hostname)

        if device_id:
            log(f"Found device {device_id} with hostname {hostname}")
            return device_id

        log(
            f"Device not found yet, waiting {delay} seconds... (attempt {attempt}/{max_attempts})"
        )
        if attempt < max_attempts:
            time.sleep(delay)

    return None


def main():
    """Main function to disable key expiry"""
    try:
        # Get configuration from environment variables set by Nix
        client_id_file = os.environ.get("TS_CLIENT_ID_FILE")
        client_secret_file = os.environ.get("TS_CLIENT_SECRET_FILE")
        tailnet_org = os.environ.get("TAILNET_ORG")
        hostname = os.environ.get("NODE_NAME")

        if not all([client_id_file, client_secret_file, tailnet_org, hostname]):
            log("ERROR: Missing required environment variables")
            log(f"TS_CLIENT_ID_FILE: {client_id_file}")
            log(f"TS_CLIENT_SECRET_FILE: {client_secret_file}")
            log(f"TAILNET_ORG: {tailnet_org}")
            log(f"NODE_NAME: {hostname}")
            sys.exit(1)

        log("Reading OAuth credentials from secrets...")

        # Read OAuth credentials
        try:
            client_id = read_secret_file(client_id_file)
            client_secret = read_secret_file(client_secret_file)
        except (FileNotFoundError, PermissionError, ValueError) as e:
            log(f"ERROR: {e}")
            sys.exit(1)

        log("Successfully read OAuth credentials")

        # Get OAuth token
        token = get_oauth_token(client_id, client_secret)
        if not token:
            sys.exit(1)

        # Wait for device to appear and get its ID
        device_id = wait_for_device(token, tailnet_org, hostname)

        if not device_id:
            log(
                f"Warning: Could not find device with hostname {hostname} to disable key expiry"
            )
            sys.exit(1)

        # Disable key expiry
        if disable_key_expiry(token, device_id):
            log("Disable key expiry completed successfully")
        else:
            sys.exit(1)

    except Exception as e:
        log(f"ERROR: Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
