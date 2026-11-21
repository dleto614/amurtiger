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

# Only print this when the output file is not empty.
if [[ -n "$OUTPUT_FILE" ]]
then
    echo "[*] Extracting unique urls from $INPUT_FILE..."
fi

# Take input file and extract urls and sort for only unique ones...
results=$(jq -r '.url // empty' "$INPUT_FILE" | sort -u)

# Handles the silly echo edge case where it always prints a newline regardless... even empty.
# Should remember this for other scripts... going to be a hard habit to break.
COUNT=$(printf '%s\n' "$results" | grep -c .) 

# Check if output file was passed as an argument.
if [[ -n "$OUTPUT_FILE" ]]
then
    printf '%s\n' "$results" > "$OUTPUT_FILE"
    echo "[*] Saved to "$OUTPUT_FILE""
else
    printf '%s\n' "$results"

fi

# Only print this when the output file is not empty.
if [[ -n "$OUTPUT_FILE" ]]
then
    echo "[*] Extraction complete. Got "$COUNT" urls from httpx file "$INPUT_FILE""
    echo "[*] Done extracting urls from "$INPUT_FILE""
fi