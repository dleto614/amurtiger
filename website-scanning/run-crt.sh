#!/usr/bin/env bash

FILE=""
DOMAIN=""
OUTPUTFILE=""
	
usage() {  # Function: Print a help message.
  echo "Usage: $0 [ -f FILE FULL OF DOMAINS TO SCAN ] 
                  [ -o OUTPUTFILE TO SAVE RESULTS ] 
                  [ -h HELP ]" 1>&2
}

exit_error() { # Function: Exit with error.
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

# Request the Search  with Domain Name
domain_lookup() {
	requestsearch="$(curl -s "https://crt.sh?q=$DOMAIN&output=json")"
	output=$(echo $requestsearch | jq ".[].common_name,.[].name_value"| cut -d'"' -f2 | sed 's/\\n/\n/g' | sed 's/\*.//g'| sed -r 's/([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4})//g' | sort -u)
    
    if [[ -n "$output" ]]
    then
        # Remove bad domains
        # This is probably incomplete.
        echo "$output" | grep -Ev "innovationcast|blastheadrecords|cloudflare|quorum|pantheonsite|google|wix|wordpress|microsoft|incapsula|bluehost|certus|twitter|facebook|bit.ly|bitly|x.com|amazon|yahoo|youtube|^$" | tee -a "$OUTPUTFILE"
    fi
}

while getopts "f:o:h" opt
do
    case ${opt} in
        f) # File with list of domains
            FILE="${OPTARG}"
            ;;
        o) # Output file
            OUTPUTFILE="${OPTARG}"
            ;;
        h) # display Help
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

# Check if file exists
if [[ ! -f "$FILE" ]]
then
    echo "[!] Host file '$FILE' does not exist"
    echo "---------------" 
    exit_error
    exit 1 
fi

# Loop through the file and lookup the domain.

while IFS= read -r line
do
    DOMAIN="$line"
    echo "[*] Checking $DOMAIN on crt.sh"
    echo "---------------"
    domain_lookup $DOMAIN
done < "$FILE"
