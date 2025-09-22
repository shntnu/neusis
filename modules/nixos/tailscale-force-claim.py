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
    print(f"[tailscale-force-claim] {message}")


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
            log(f"ERROR: Failed to obtain OAuth token")
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


def find_current_and_conflicting_devices(devices, hostname, current_ips):
    """Find current device and any conflicting devices"""
    current_device = None
    conflicting_devices = []

    for device in devices:
        device_hostname = device.get("hostname", "")
        device_name = device.get("name", "").lower().split(".")[0]
        device_addresses = device.get("addresses", [])

        # Check if this is the current device by comparing IPs
        is_current_device = any(ip in device_addresses for ip in current_ips)

        if is_current_device:
            current_device = device
            log(
                f"Found current device: {device.get('nodeId')} with hostname={device_hostname}, name={device_name}"
            )

            # Check if hostname matches name for current device
            if device_hostname == device_name:
                log("Current device hostname matches name - no action needed")
                return current_device, []
            else:
                log(
                    f"Current device hostname ({device_hostname}) differs from name ({device_name})"
                )

        # Check for conflicting devices (name matches our hostname but different device)
        elif device_name == hostname:
            conflicting_devices.append(device)
            log(
                f"Found conflicting device: {device.get('nodeId')} with hostname={device_hostname}, name={device_name}"
            )

    return current_device, conflicting_devices


def delete_device(token, device_id, hostname):
    """Delete a device by ID"""
    log(f"Deleting device {device_id} with hostname {hostname}")

    req = urllib.request.Request(
        f"https://api.tailscale.com/api/v2/device/{device_id}",
        headers={"Authorization": f"Bearer {token}"},
        method="DELETE",
    )

    try:
        with urllib.request.urlopen(req) as response:
            response.read()  # Consume response
        log(f"Successfully deleted device {device_id}")
        return True
    except urllib.error.URLError as e:
        log(f"ERROR: Failed to delete device {device_id}: {e}")
        return False


def set_device_name(token, device_id, name):
    """Set device name using Tailscale API"""
    log(f"Setting device {device_id} name to: {name}")

    data = json.dumps({"name": name}).encode("utf-8")

    req = urllib.request.Request(
        f"https://api.tailscale.com/api/v2/device/{device_id}/name",
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
        log(f"Successfully set device {device_id} name to {name}")
        return True
    except urllib.error.URLError as e:
        log(f"ERROR: Failed to set device {device_id} name: {e}")
        return False


def main():
    """Main function to force claim hostname"""
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

        # Get all devices from Tailscale
        devices = get_tailscale_devices(token, tailnet_org)
        if not devices:
            log("ERROR: Could not fetch devices from Tailscale API")
            sys.exit(1)

        # Find current device and any conflicting devices
        current_device, conflicting_devices = find_current_and_conflicting_devices(
            devices, hostname, current_ips
        )

        if not current_device:
            log("ERROR: Could not identify current device")
            sys.exit(1)

        # Delete conflicting devices if any exist
        if conflicting_devices:
            log(f"Found {len(conflicting_devices)} conflicting devices to delete")
            for device in conflicting_devices:
                device_id = device.get("nodeId")
                device_hostname = device.get("hostname", "unknown")
                if device_id:
                    delete_device(token, device_id, device_hostname)
        else:
            log("No conflicting devices found")

        # Set current device name to hostname if they don't match
        current_device_hostname = current_device.get("hostname", "")
        # Make sure to lower the string before comparison
        current_device_name = current_device.get("name", "").lower().split(".")[0]
        current_device_id = current_device.get("nodeId")

        if current_device_hostname != current_device_name:
            log(
                f"Setting current device name from '{current_device_name}' to '{hostname}'"
            )
            if current_device_id:
                set_device_name(token, current_device_id, hostname)
            else:
                log("ERROR: Could not get current device ID")
        else:
            log("Current device hostname already matches name")

        log("Force claim hostname completed successfully")

    except Exception as e:
        log(f"ERROR: Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
