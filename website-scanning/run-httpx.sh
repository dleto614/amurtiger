#!/usr/bin/env bash

FILE=""
OUTPUTFILE=""
FILTER=""

usage() {
  echo "Usage: $0 [ -f FILE OF DOMAINS TO PROBE ]
        [ -o OUTPUT FILE TO SAVE RESULTS ]
        [ -t TECH TO FILTER BY (eg -t wordpress, jenkins, apache) (OPTIONAL) ]
        [ -h HELP ]" 1>&2
}

exit_error() {
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

while getopts "f:o:t:h" opt
do
    case ${opt} in
        f)
            FILE="${OPTARG}"
            ;;
        o)
            OUTPUTFILE="${OPTARG}"
            ;;
        t)
            echo "[*] Filtering for tech: ${OPTARG}"
            FILTER="${OPTARG}"
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
    echo "[!] Host file '$FILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

echo "[*] Probing hosts for HTTP services..."
echo "---------------"

# If a tech filter was supplied, use jq to parse for it
# --arg tech "$FILTER" safely passes the bash variable into jq
if [[ -n "$FILTER" ]]
then
    cat "$FILE" | httpx -silent -json -td | jq --arg tech "$FILTER" -r 'select(.tech != null) | select(.tech[] | test($tech; "i")) | .url' | sort -u > "$OUTPUTFILE"
else
    # If no filter, just output all live URLs
    cat "$FILE" | httpx -silent -json -td | jq -r '.url' | sort -u > "$OUTPUTFILE"
fi

echo "[*] Probing complete. Results saved to: $OUTPUTFILE"
