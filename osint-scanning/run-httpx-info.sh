#!/usr/bin/env bash

FILE=""
OUTPUT_FILE=""

usage() {
  echo "Usage: $0 [ -f FILE OF DOMAINS ]
        [ -o OUTPUT JSON FILE ]
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
            OUTPUT_FILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
    esac
done

if [[ -z "$FILE" || -z "$OUTPUT_FILE" ]]
then
    echo "[!] Not all required arugments were supplied"
    echo "---------------"
    exit_error
    exit 1
fi

if [[ ! -f "$FILE" ]]
then
    echo "[!] Inputted file '$FILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

echo "[*] Running HTTPX on file '$FILE' and dumping results into JSON..."
httpx -l "$FILE" -silent -json -td -status-code -favicon -asn -o "$OUTPUT_FILE"

echo "[*] HTTPX is done running."