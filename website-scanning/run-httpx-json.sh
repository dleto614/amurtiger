#!/usr/bin/env bash

FILE=""
OUTPUTFILE=""

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
    echo "[!] Inputted file '$FILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

echo "[*] Dumping all tech to JSON..."
httpx -silent -json -td -l "$FILE" -o "$OUTPUTFILE"
