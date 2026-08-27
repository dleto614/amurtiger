#!/usr/bin/env bash

INPUTFILE=""
TECHLIST=""
OUTPUTFILE=""

usage() {
  echo "Usage: $0 [ -f HTTPX JSON FILE ]
        [ -t TECH KEYWORD TO FILTER FOR ]
        [ -o OUTPUT FILE (optional, defaults to stdout) ]
        [ -h HELP ]" 1>&2
}

exit_error() {
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

while getopts "f:t:o:h" opt
do
    case ${opt} in
        f)
            INPUTFILE="${OPTARG}"
            ;;
        t)
            TECHLIST="${OPTARG}"
            ;;
        o)
            OUTPUTFILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
        :)
            echo "[!] Missing argument for -${OPTARG}" 1>&2
            exit_error
            ;;
        *)
            exit_error
            ;;
    esac
done

if [[ -z "$INPUTFILE" || -z "$TECHLIST" ]]
then
    echo "[!] Not all required arguments were supplied (-f and -t are required)"
    echo "---------------"
    exit_error
    exit 1
fi

if [[ ! -f "$INPUTFILE" ]]
then
    echo "[!] Inputted file '$INPUTFILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo "[!] 'jq' is required but not installed."
    echo "---------------"
    exit_error
    exit 1
fi

JQ_FILTER='select(.tech != null) | select(.tech[] | . as $tech_item | any($techlist | ascii_downcase | split(",")[]; . as $search | ($tech_item | ascii_downcase | contains($search)))) | .url'

# Handle stdout vs file output
if [[ -n "$OUTPUTFILE" ]]
then
    echo "[*] Extracting URLs matching tech: $TECHLIST"
    echo "---------------"

    # Clear the output file at the start so we append cleanly
    > "$OUTPUTFILE"

    # FIX: Added --arg techlist to safely pass the variable into jq
    # Run jq and redirect to file, then deduplicate
    jq -r --arg techlist "$TECHLIST" "$JQ_FILTER" "$INPUTFILE" | sort -u >> "$OUTPUTFILE" 2>/dev/null

    # Count results
    count=$(wc -l < "$OUTPUTFILE")

    echo "[*] Extraction complete. Found $count matching URLs."
    echo "[*] Saved to: $OUTPUTFILE"
else
    # Run jq to stdout and deduplicate
    results=$(jq -r --arg techlist "$TECHLIST" "$JQ_FILTER" "$INPUTFILE" 2>/dev/null | sort -u)

  echo "$results"

fi
