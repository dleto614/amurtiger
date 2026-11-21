#!/usr/bin/env bash

INPUT_FILE=""
OUTPUT_FILE=""

usage() {
  echo "Usage: $0 [ -f HTTPX JSON FILE ]
        [ -o OUTPUT FILE TO SAVE RESULTS ]
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

if [[ -z "$INPUT_FILE" ]]
then
    echo "[!] You must input a file with the httpx results in json format."
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

echo "[*] Extracting unique urls from $INPUT_FILE..."

# Take input file and extract unique ips than feed it into tlsx.
results=$(jq -r '.url' "$INPUT_FILE" | sort -u)

COUNT=$(echo "$results" | wc -l) # Don't likey this as is right now...

# Check if output file was passed as an argument.
if [[ -n "$OUTPUT_FILE" ]]
then
    echo "$results" >> "$OUTPUT_FILE"
    echo "[*] Saved to "$OUTPUT_FILE""
else
    echo "$results"

fi

echo "[*] Extraction complete. Got "$COUNT" urls from httpx file "$INPUT_FILE""
echo "[*] Done extracting urls from "$INPUT_FILE""