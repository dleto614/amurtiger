#!/usr/bin/env bash

INPUT_FILE=""
OUTPUT_FILE=""

usage() {
  echo "Usage: $0 [ -f HTTPX JSON FILE ]
        [ -o OUTPUT FILE TO SAVE TLSX RESULTS ]
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
            INPUT_FILE="${OPTARG}"
            ;;
        o)
            OUTPUT_FILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
    esac
done

if [[ -z "$INPUT_FILE" || -z "$OUTPUT_FILE" ]]
then
    echo "[!] Not all required arguments were supplied"
    echo "---------------"
    exit_error
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]
then
    echo "[!] Inputted file '$INPUT_FILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

echo "[*] Extracting unique IPs from $INPUT_FILE..."

# Take input file and extract unique ips than feed it into tlsx.
cat "$INPUT_FILE" | jq -r '.a[]? // .host_ip // empty' | sort -u | tlsx -silent -json -san -cn -o "$OUTPUT_FILE"

COUNT=$(wc -l < "$OUTPUT_FILE")

echo "[*] Extraction complete. Got $COUNT successful tls connections and results with tlsx."
echo "[*] Saved to $OUTPUT_FILE"