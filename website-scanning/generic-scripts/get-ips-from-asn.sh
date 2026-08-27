#!/usr/bin/env bash

ASNFILE=""
OUTPUTFILE=""

usage() {
  echo "Usage: $0 [ -f FILE OF ASNs ]
        [ -o OUTPUT FILE FOR IP RANGES ]
        [ -h HELP ]" 1>&2
}

exit_error() {
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

while getopts "f:o:h" opt
do
    case ${opt} in
        f)
            ASNFILE="${OPTARG}"
            ;;
        o)
            OUTPUTFILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
    esac
done

if [[ -z "$ASNFILE" || -z "$OUTPUTFILE" ]]
then
    echo "[!] Not all required arugments were supplied"
    echo "---------------"
    exit_error
    exit 1
fi

if [[ ! -f "$ASNFILE" ]]
then
    echo "[!] Inputted file '$ASNFILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

# Clear the output file at the start so we append cleanly
> "$OUTPUTFILE"

echo "[*] Resolving ASNs to IP ranges..."
echo "---------------"

count=0
while IFS= read -r asn; do
    # Strip whitespace just in case
    asn=$(echo "$asn" | tr -d '[:space:]')
    
    # Skip empty lines
    [[ -z "$asn" ]] && continue
    
    # Query RADB whois for the ASN and extract CIDR ranges
    # Regex matches formats like 192.168.1.0/24 or 10.0.0.0/16
    ranges=$(whois -h whois.radb.net -i origin "$asn" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}" | sort -t . -k1,1n -k2,2n -k3,3n -k4,4n)

    if [[ -n "$ranges" ]]; then
        # Output exactly one range per line (critical for hakrevdns/nuclei)
        echo "$ranges" >> "$OUTPUTFILE"
        ((count++))
        echo "[*] Found ranges for ASN: $asn"
    else
        echo "[!] No ranges found for ASN: $asn"
    fi
done < "$ASNFILE"

echo "---------------"
echo "[*] Resolution complete. Found ranges for $count ASNs."
echo "[*] Saved to: $OUTPUTFILE"
