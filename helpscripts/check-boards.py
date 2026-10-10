#!/usr/bin/env python3
"""Compare the configuration reported by every dScript board with the target state of config-MKrooms.sh.

Usage (WSL, repository root):
    python3 ./helpscripts/check-boards.py            # check all rooms
    python3 ./helpscripts/check-boards.py buero kueche   # check selected rooms only
    python3 ./helpscripts/check-boards.py -v         # also print the matching boards

How it works: the board command GetConfig (0x50, binary protocol, TCP 17123) returns 12 bytes:
MAC (6 bytes), physical relays, lights, shutters, sockets, motion sensors, buttons.
The target counts below are derived from config-MKrooms.sh (lights/shutters variables and
the number of --iotype='motion' / 'button' lines per room). Keep both in sync.

Exit code: 0 = all boards match, 1 = at least one mismatch, 2 = at least one board unreachable.
"""
import socket
import sys

PORT = 17123
TIMEOUT = 5
CMD_GETCONFIG = 0x50

# room: (current IP, lights, shutters, motions, buttons) - target state from config-MKrooms.sh
ROOMS = {
    "gaestebad":  ("192.168.28.77",  3, 1, 1, 0),
    "windfang":   ("192.168.28.46",  4, 0, 2, 0),
    "kueche":     ("192.168.28.183", 4, 2, 1, 0),
    "speis":      ("192.168.28.47",  1, 0, 1, 1),
    "wohnzimmer": ("192.168.28.45",  0, 4, 1, 1),
    "technik":    ("192.168.28.59",  2, 2, 1, 0),
    "garderobe":  ("192.168.28.48",  1, 1, 1, 0),
    "hauptbad":   ("192.168.28.53",  2, 2, 1, 2),
    "kind":       ("192.168.28.81",  1, 2, 1, 0),
    "ankleide":   ("192.168.28.55",  1, 0, 1, 0),
    "gaeste":     ("192.168.28.112", 1, 2, 1, 0),
    "gang":       ("192.168.28.187", 1, 1, 2, 0),
    "buero":      ("192.168.28.30",  1, 2, 1, 3),
    "schlafen":   ("192.168.28.50",  0, 1, 1, 2),
    "dachboden":  ("192.168.28.250", 3, 0, 2, 0),
    "garage":     ("192.168.28.104", 7, 0, 1, 2),
    "keller":     ("192.168.28.103", 4, 0, 1, 3),
}


def resolve(room, ip):
    """Prefer the hostname dS-<room>, fall back to the known IP."""
    try:
        return socket.gethostbyname("dS-" + room)
    except OSError:
        return ip


def get_config(host):
    """Send GetConfig and return the 12 reply bytes."""
    with socket.create_connection((host, PORT), timeout=TIMEOUT) as s:
        s.settimeout(TIMEOUT)
        s.sendall(bytes([CMD_GETCONFIG]))
        data = b""
        while len(data) < 12:
            chunk = s.recv(12 - len(data))
            if not chunk:
                break
            data += chunk
    return data


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    verbose = "-v" in sys.argv[1:]
    unknown = [a for a in args if a not in ROOMS]
    if unknown:
        print("unknown room(s): %s" % ", ".join(unknown))
        return 2
    rooms = args or list(ROOMS)
    mismatch = unreachable = 0
    print("%-11s %-15s %-9s %s" % ("room", "host", "result", "details (reported / target)"))
    for room in rooms:
        ip, lights, shutters, motions, buttons = ROOMS[room]
        host = resolve(room, ip)
        try:
            data = get_config(host)
        except OSError as e:
            print("%-11s %-15s %-9s %s" % (room, host, "NO REPLY", e))
            unreachable += 1
            continue
        if len(data) < 12:
            print("%-11s %-15s %-9s empty or short reply (%d bytes)" % (room, host, "NO DATA", len(data)))
            unreachable += 1
            continue
        reported = {"lights": data[7], "shutters": data[8], "motions": data[10], "buttons": data[11]}
        target = {"lights": lights, "shutters": shutters, "motions": motions, "buttons": buttons}
        diff = ["%s %d/%d" % (k, reported[k], target[k]) for k in target if reported[k] != target[k]]
        if diff:
            mismatch += 1
            print("%-11s %-15s %-9s %s" % (room, host, "MISMATCH", ", ".join(diff)))
        elif verbose:
            print("%-11s %-15s %-9s relays %d, sockets %d, %s" % (room, host, "ok", data[6], data[9],
                  ", ".join("%s %d" % (k, v) for k, v in reported.items())))
    print("\nmismatch: %d, unreachable: %d, checked: %d" % (mismatch, unreachable, len(rooms)))
    if unreachable:
        return 2
    return 1 if mismatch else 0


if __name__ == "__main__":
    sys.exit(main())
