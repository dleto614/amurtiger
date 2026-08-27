#!/usr/bin/env bash

FILE=""
OUTPUTFILE=""

usage() {
  echo "Usage: $0 [ -f FILE OF IP RANGES/CIDRS ]
        [ -o OUTPUT FILE TO SAVE DOMAINS ]
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
            FILE="${OPTARG}"
            ;;
        o)
            OUTPUTFILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
    esac
done

if [[ -z "$FILE" || -z "$OUTPUTFILE" ]]
then
    echo "[!] Not all required arugments were supplied"
    echo "---------------"
    exit_error
    exit 1
fi

if [[ ! -f "$FILE" ]]
then
    echo "[!] IP/Ranges file '$FILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

echo "[*] Starting Reverse DNS brute force on supplied IP ranges..."
echo "---------------"

# hakrevdns does the heavy lifting
# sort -u deduplicates the found domains
# grep -Ev runs your exact exclusion list to drop garbage domains
cat "$FILE" | hakrevdns -d -r 1.1.1.1 | sort -u | grep -Ev "innovationcast|blastheadrecords|cloudflare\.com|quorum|pantheonsite\.io|google\.com|wix\.com|wordpress\.com|microsoft\.com|incapsula\.com|bluehost\.com|certus|twitter\.com|facebook\.com|bit\.ly|x\.com|amazon\.com|yahoo\.com|youtube\.com|^$" > "$OUTPUTFILE"

echo "[*] Reverse DNS complete. Clean results saved to: $OUTPUTFILE"
