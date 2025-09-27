#!/usr/bin/env python3
"""
snmpv3_extract_jtr.py
Extract SNMPv3 packets with pyshark and write John the Ripper $SNMPv3$ hashes to a file.
Process_packets logic matches the original snmpv3brute.py behavior for pyshark.
"""

# TODO: Add more options like specifying output file, verbose, hashcat mode, etc.

import argparse
import sys
from binascii import unhexlify
import pyshark

def print_banner():
    banner = r"""
[========================================]
[========================================] 
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠀⠀⠐⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⢿⣗⢄⣤⡌⠁⡀⢀⢠⣄⣂⡔⣺⣿⡄⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⠛⣩⣾⣳⢎⣢⡐⣶⣿⣯⠻⣿⣏⠐⠘⠂⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠘⢉⠋⠑⡛⠁⠘⠿⠟⠹⣛⠚⣹⡏⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠁⣷⠸⠤⠀⠀⠀⠀⣄⡀⠀⢱⣾⣥⢇⣾⠸⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣤⠙⠠⠌⠀⠀⣦⣌⢋⣥⣾⣬⣿⣦⠤⠃⣰⣻⡏⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⣧⣤⠖⠀⠀⣩⣉⣌⣹⡋⠋⢽⣿⣿⣿⡿⣿⠂
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠈⢉⣁⠀⠀⠉⠛⠙⠛⠣⢌⣸⣿⡿⡿⠟⣋⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣷⣦⣌⠙⠦⣴⣤⣶⣶⣾⡟⠿⠗⠁⣤⣾⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣀⠀⢀⡄⢀⡀⠀⠀⠀⣠⣶⣦⣜⢿⣿⣿⡄⠘⣿⡿⣿⣷⡶⢶⣣⣾⣿⠿⢛⣵⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢁⣴⠏⢠⠎⠀⠀⣰⣦⡙⠿⣿⣿⣧⡙⢿⣿⣤⡻⣷⣼⡿⣷⣿⣿⠟⣡⣴⣿⣿⣿⠧⡀⠀⠀⠀⠀⠀⠀⠀
⠻⡇⡴⢫⣦⣴⣿⣿⣿⣿⣦⠘⣿⣿⣿⢘⣿⣿⣷⣴⢿⣳⣿⣿⢁⣾⣿⣿⠿⠋⣠⣾⣿⣶⣄⠀⠀⠀⠀⠀
⠀⡿⢡⢻⣿⣿⣿⣿⣿⣿⣿⣦⣿⣿⣷⣾⣿⣋⣿⡟⣴⣿⣿⠿⠛⠉⠉⡠⢖⣹⠽⠋⣱⣿⣿⣧⠀⠀⠀⠀
⠀⠃⠀⠀⠀⢹⣿⣿⣫⣴⣾⣧⠙⠛⠛⠛⠻⠟⠿⠛⠛⠛⠈⠀⠀⠀⠀⠀⠋⠀⢴⣿⣿⣿⣿⣟⣷⡀⠀⠀
⠤⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⡇⠀⠀⠋⠉⠍⠙⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⣿⣿⡧⠀⠀
[===⢠⣿⣿⣿⣿⣿⣿⡇===================⠠⣿⣿⣿⣿⣿⡇===]
[==⢀⣿⣿⣿⣿⣿⣿⡿⠃===================⠐⢹⠟⣿⣿⣿⡇===]
[==⠩⡿⢷⣿⡿⡿⠁======================⢷⣴⣿⣿⣿⡇===]
[================================⠉⠾⠿⠁====]
[=====   < SNMPv3 Hash Extractor >  =====]
[============  < By: Alex >  ============]
[========================================]
[========================================]  
    """
    print(banner)

def normalize_hex_str(s):
    if s is None:
        return None
    return str(s).replace(":", "").replace(" ", "").lower()

def field_to_hex(field):
    """Convert a pyshark field (raw bytes/list/objects) to normalized hex string."""
    if field is None:
        return None
    # If list-like (pyshark raw fields often are), take first element
    try:
        if isinstance(field, (list, tuple)) and field:
            field = field[0]
    except Exception:
        pass
    # If bytes
    if isinstance(field, (bytes, bytearray)):
        return field.hex()
    # If pyshark field-like with .raw_value or .value
    if hasattr(field, 'raw_value'):
        return normalize_hex_str(field.raw_value)
    if hasattr(field, 'value'):
        return normalize_hex_str(field.value)
    # Fallback to string normalization
    return normalize_hex_str(str(field))

def process_packets(pcap, verbose=False):
    """
    Used to extract SNMPv3 packets from pcap.
    Mirrors original snmpv3brute.py process_packets logic (no manual mode).
    Returns list of tasks:
      [ip_src, ip_dst, username, engine_raw, auth_raw, whole_raw, counter]
    where engine_raw/auth_raw/whole_raw are the raw objects returned by pyshark
    (matching original code that used ._raw and .value).
    """
    tasks = []
    counter = 1

    print("Looking for SNMPv3 packets in {}...".format(pcap))
    cap = pyshark.FileCapture(
        pcap,
        display_filter='udp.srcport==161&&snmp.msgVersion==3&&snmp.msgUserName!=""',
        include_raw=True,
        use_json=True
    )

    for pkt in cap:
        update = True
        try:
            # Only consider packets from UDP src port 161 and SNMPv3
            if int(pkt.udp.srcport) == 161 and int(pkt.snmp.msgVersion) == 3:
                for t in tasks:
                    # replicate original comparison semantics
                    # note: pkt.snmp.msgUserName might be a pyshark field; compare string forms
                    pkt_src = getattr(pkt.ip, 'src', None)
                    pkt_dst = getattr(pkt.ip, 'dst', None)
                    pkt_un = getattr(pkt.snmp, 'msgUserName', None)
                    # t stored earlier entries (original stored objects) — compare string forms for consistency
                    if (str(pkt_src) != str(t[0])) or (str(pkt_dst) != str(t[1])) or (str(pkt_un) != str(t[2])):
                        update = True
                    else:
                        update = False
            else:
                update = False
        except Exception:
            # If anything unexpected, skip this packet
            update = False

        if update == True:
            try:
               # Append fields using the same attributes as the original script
               # This was the part that fucked me in bash.
               tasks.append([
                  pkt.ip.src,
                  pkt.ip.dst,
                  pkt.snmp.msgUserName,
                  pkt.snmp.msgAuthoritativeEngineID_raw[0],
                  pkt.snmp.msgAuthenticationParameters_raw[0],
                  pkt.snmp_raw.value,
                  counter
               ])
               counter += 1
            except AttributeError:
               if verbose:
                  print("An attribute is missing in packet {}, skipping...".format(getattr(pkt.frame_info, "number", "?")))
            except Exception:
               if verbose:
                  print("An error occured with packet {}, skipping...".format(getattr(pkt.frame_info, "number", "?")))
    cap.close()
    return tasks

def build_jtr_from_task(t):
    """
    Build JtR hash:
    username:$SNMPv3$0$0$<wholeMsgMod_hex>$<engineID_hex>$<authParam_hex>
    Convert the raw fields to hex using field_to_hex.
    """
    username = str(t[2])
    engine_hex = field_to_hex(t[3])
    auth_hex = field_to_hex(t[4])
    whole_hex = field_to_hex(t[5])

    if not (engine_hex and auth_hex and whole_hex):
        raise ValueError("Missing required raw fields for task")

    zeros24 = '0' * 24
    whole_zeroed = whole_hex.replace(auth_hex, zeros24)
    try:
        wholeMsgMod = unhexlify(whole_zeroed)
    except Exception:
        wholeMsgMod = bytes.fromhex(whole_zeroed)
    der_hex = wholeMsgMod.hex()
    return f"{username}:$SNMPv3$0$0${der_hex}${engine_hex}${auth_hex}"

def main():
    parser = argparse.ArgumentParser(description="Extract SNMPv3 packets and write JtR $SNMPv3$ hashes to a file")
    parser.add_argument("-p", required=True, help="Specify .pcap/.pcapng file with SNMPv3 data")
    parser.add_argument("-o", default="hashes.txt", help="Output file for JtR hashes (default: hashes.txt)")
    parser.add_argument("-v", action="store_true", help="Verbose; print error messages")
    args = parser.parse_args()

    taskList = process_packets(args.p, args.v)

    if not taskList:
        print("No SNMPv3 packets found.")
        sys.exit(0)

    seen = set()
    written = 0
    with open(args.o, "w") as fh:
        for t in taskList:
            try:
                engine_hex = field_to_hex(t[3])
                auth_hex = field_to_hex(t[4])
                if not (engine_hex and auth_hex):
                    if args.v:
                        print(f"Skipping task {t[6]} - missing engine/auth hex")
                    continue
                key = f"{engine_hex}|{auth_hex}"
                if key in seen:
                    continue
                seen.add(key)
                jtr = build_jtr_from_task(t)
                fh.write(jtr + "\n")
                written += 1
            except Exception as e:
                if args.v:
                    print(f"Error building JtR for task {t[6]}: {e}")

    print(f"Wrote {written} unique hashes to {args.o}")

if __name__ == "__main__":
    print_banner()
    print("Starting SNMPv3 Hash Extractor...\n")
    main()

