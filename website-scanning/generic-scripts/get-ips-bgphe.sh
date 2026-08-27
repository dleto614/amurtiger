#!/usr/bin/env bash

# cURL Command:
# curl -s -L \
#     -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" \
#     -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" \
#     -H "Accept-Language: en-US,en;q=0.9" \
#     -H "Referer: https://bgp.he.net/" \
#     "https://bgp.he.net/${asn}" | \
#     grep -oP 'href="/net/\K[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}'

ASN_FILE=""
OUTPUT_FILE=""

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
            ASN_FILE="${OPTARG}"
            ;;
        o)
            OUTPUT_FILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
    esac
done

# Check if an ASN_FILE was passed or not.
if [[ -z "$ASN_FILE" ]]
then
    echo "[!] Error: Specify the file with the ASN to lookup."
    echo ""
    exit_error
fi

# Read file in a while loop.
while IFS= read -r asn
do
    response=$(curl -s -L \
                -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" \
                -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" \
                -H "Accept-Language: en-US,en;q=0.9" \
                -H "Referer: https://bgp.he.net/" \
                "https://bgp.he.net/${asn}" | \
                grep -oP 'href="/net/\K[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}')
    
    # Check if response is empty or not and if output file was passed
    if [[ -n "$response" && -n "$OUTPUT_FILE" ]]
    then
        
        # Get total results
        # Pipe the variable to wc -l, and use xargs to trim the empty spaces wc adds
        num_results=$(echo "$response" | sort -u | wc -l | xargs)
        
        echo "$response" | sort -u >> "$OUTPUT_FILE"
        
        # Clean, simple quoting
        echo "[*] Wrote $num_results results to output file $OUTPUT_FILE for ASN: $asn"

    elif [[ -n "$response" && -z "$OUTPUT_FILE" ]]
    then
        echo "$response" | sort -u
    fi
        
    sleep 3 # To be polite. Could probably reduce to 1 second, but...
done < "$ASN_FILE"