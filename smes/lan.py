"""Serve the board on every network interface and print LAN addresses.

Other computers must open http://<this-pc-lan-ip>:8000.
http://127.0.0.1:8000 works only on the computer running this process.
"""

from __future__ import annotations

import socket
import webbrowser
from ipaddress import ip_address

import uvicorn


def _is_usable(address: str) -> bool:
    try:
        value = ip_address(address)
    except ValueError:
        return False
    return value.version == 4 and not (
        value.is_loopback or value.is_link_local or value.is_unspecified
    )


def lan_addresses() -> list[str]:
    """Every non-loopback IPv4 address other devices might use to reach this PC."""
    found: set[str] = set()
    hostname = socket.gethostname()
    try:
        for info in socket.getaddrinfo(hostname, None, socket.AF_INET):
            candidate = info[4][0]
            if _is_usable(candidate):
                found.add(candidate)
    except socket.gaierror:
        pass

    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        probe.connect(("8.8.8.8", 80))
        candidate = probe.getsockname()[0]
        if _is_usable(candidate):
            found.add(candidate)
    except OSError:
        pass
    finally:
        probe.close()

    return sorted(found)


def lan_ip() -> str | None:
    addresses = lan_addresses()
    return addresses[0] if addresses else None


def main() -> None:
    addresses = lan_addresses()
    print("=" * 60, flush=True)
    print("SMES LAN SERVER", flush=True)
    print("=" * 60, flush=True)
    print("Listening on ALL network interfaces, port 8000.", flush=True)
    print("", flush=True)
    print("THIS computer only:", flush=True)
    print("  http://127.0.0.1:8000", flush=True)
    print("", flush=True)
    if addresses:
        print("OTHER users on the SAME network must open ONE of these:", flush=True)
        for address in addresses:
            print(f"  http://{address}:8000", flush=True)
    else:
        print("No LAN address found. Connect Ethernet/Wi-Fi, then start again.", flush=True)
    print("", flush=True)
    print("Leave this window OPEN. Closing it stops the board for everyone.", flush=True)
    print("Other users must use the SAME Wi-Fi/LAN. Do NOT use 127.0.0.1 on their phones.", flush=True)
    print("=" * 60, flush=True)
    try:
        webbrowser.open("http://127.0.0.1:8000")
    except Exception:
        pass
    uvicorn.run("smes.main:app", host="0.0.0.0", port=8000, log_level="info")


if __name__ == "__main__":
    main()
