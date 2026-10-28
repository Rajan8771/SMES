"""Serve the board on every network interface and print the LAN address.

Other computers must open the printed http://<this-pc-lan-ip>:8000 address.
http://127.0.0.1:8000 works only on the computer running this process.
"""

from __future__ import annotations

import socket

import uvicorn


def lan_ip() -> str | None:
    """Address other devices on this network use to reach this computer."""
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        probe.connect(("8.8.8.8", 80))
        address = probe.getsockname()[0]
    except OSError:
        return None
    finally:
        probe.close()
    if address.startswith("127."):
        return None
    return address


def main() -> None:
    address = lan_ip()
    print("SMES is listening on all network interfaces, port 8000.", flush=True)
    print("This computer:        http://127.0.0.1:8000", flush=True)
    if address:
        print(f"Other users on LAN:   http://{address}:8000", flush=True)
    else:
        print("No LAN address found. Connect this computer to Wi-Fi, then start again.", flush=True)
    print("Leave this window open. Other users must be on the same Wi-Fi or LAN.", flush=True)
    uvicorn.run("smes.main:app", host="0.0.0.0", port=8000)


if __name__ == "__main__":
    main()
