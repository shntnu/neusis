#!/usr/bin/env python3

import json
import os
import subprocess
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


def wait_for_tailscale_connection(max_attempts=30, delay=5):
    """Wait for Tailscale to be connected before proceeding"""
    log("Waiting for Tailscale connection...")

    for attempt in range(1, max_attempts + 1):
        try:
            # Check if tailscale is up and has an IP
            result = subprocess.run(
                ["tailscale", "status", "--json"],
                capture_output=True, text=True, check=True
            )
            status = json.loads(result.stdout)

            # Check if we have BackendState == "Running" and have an IP
            if status.get("BackendState") == "Running" and status.get("Self", {}).get("TailscaleIPs"):
                log("Tailscale is connected")
                return True

        except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError):
            pass

        if attempt < max_attempts:
            log(f"Tailscale not ready, waiting {delay}s... (attempt {attempt}/{max_attempts})")
            time.sleep(delay)

    log("ERROR: Tailscale did not connect after maximum attempts")
    return False


def get_current_device_ips():
    """Get current device IPs using tailscale ip command"""
    try:
        result = subprocess.run(
            ["tailscale", "ip"], capture_output=True, text=True, check=True
        )
        ips = [ip.strip() for ip in result.stdout.strip().split("\n") if ip.strip()]
        log(f"Current device IPs: {ips}")
        return ips
    except subprocess.CalledProcessError as e:
        log(f"ERROR: Failed to get current device IPs: {e}")
        return []
    except FileNotFoundError:
        log(f"ERROR: tailscale command not found")
        return []


def get_tailscale_devices(token, tailnet_org):
    """Get all devices from Tailscale API"""
    log("Fetching all devices from Tailscale API...")

    req = urllib.request.Request(
        f"https://api.tailscale.com/api/v2/tailnet/{tailnet_org}/devices",
        headers={"Authorization": f"Bearer {token}"},
    )

    try:
        with urllib.request.urlopen(req) as response:
            response_data = response.read().decode("utf-8")

        devices_response = json.loads(response_data)
        devices = devices_response.get("devices", [])

        log(f"Found {len(devices)} devices in tailnet")
        return devices

    except urllib.error.URLError as e:
        log(f"ERROR: Failed to fetch devices: {e}")
        return []
    except json.JSONDecodeError as e:
        log(f"ERROR: Invalid JSON response from devices API: {e}")
        return []


def find_current_device(devices, current_ips):
    """Find current device by matching IPs"""
    for device in devices:
        device_addresses = device.get("addresses", [])

        # Check if this is the current device by comparing IPs
        if any(ip in device_addresses for ip in current_ips):
            log(
                f"Found current device: {device.get('nodeId')} with keyExpiryDisabled={device.get('keyExpiryDisabled', False)}"
            )
            return device

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


def wait_for_current_device(token, tailnet_org, current_ips, max_attempts=12, delay=5):
    """Wait for current device to appear in the tailnet with retries"""
    log("Waiting for current device to appear in tailnet...")

    for attempt in range(1, max_attempts + 1):
        devices = get_tailscale_devices(token, tailnet_org)
        if devices:
            current_device = find_current_device(devices, current_ips)
            if current_device:
                return current_device

        log(
            f"Current device not found yet, waiting {delay} seconds... (attempt {attempt}/{max_attempts})"
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

        # Wait for Tailscale to be connected
        if not wait_for_tailscale_connection():
            log("ERROR: Tailscale is not connected")
            sys.exit(1)

        # Get current device IPs
        current_ips = get_current_device_ips()
        if not current_ips:
            log("ERROR: Could not determine current device IPs")
            sys.exit(1)

        # Wait for current device to appear and get its details
        current_device = wait_for_current_device(token, tailnet_org, current_ips)

        if not current_device:
            log("Warning: Could not find current device to disable key expiry")
            sys.exit(1)

        # Check if key expiry is already disabled
        if current_device.get("keyExpiryDisabled", False):
            log("Key expiry is already disabled for current device")
            return

        # Disable key expiry
        device_id = current_device.get("nodeId")
        if device_id and disable_key_expiry(token, device_id):
            log("Disable key expiry completed successfully")
        else:
            log("ERROR: Failed to disable key expiry")
            sys.exit(1)

    except Exception as e:
        log(f"ERROR: Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
