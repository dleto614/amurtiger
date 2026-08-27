#!/usr/bin/env bash

FILE=""
OUTPUTFILE=""

usage() {
  echo "Usage: $0 [ -f FILE OF DOMAINS  ]
        [ -o OUTPUT FILE ]
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

if [[ -z "$FILE" ]]
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

echo "[*] Starting Katana crawl..."

output=$(katana -list "$FILE" -d 10 -timeout 30 -kf all -c 5 -rl 15 -silent -nc)

if [[ -n "$OUTPUTFILE" ]]
then
    echo "$output" | tee -a "$OUTPUTFILE"
else
    echo "$output"
fi
