#!/usr/bin/env bash

# TODO: Add background processes count thing (can't have threads so have a different way of doing this).

#-----------------------------#
# Code example:               #
#-----------------------------#
# count=0
# while IFS= read -r line
# do
#     whatever command &
#
#     ((count++))
#
# 	# Check if count is divisible by n via modulus
#     if [ $((count % n)) -eq 0 ]
#     then
#         echo "Reached maximum of number of processes to run in the background"
#         echo "Waiting for them to finish in the background"
#         wait # Wait for the current background processes to finish running before continuing
#     fi
#
# done < whatever
#-----------------------------#

# TODO: Add vhost mode.
# TODO: Might add httpx optional flag to run httpx on found domains.

DOMAIN=""

INPUT=""
OUTPUT=""
WORDLIST=""

OUTPUT_DIRS=""
OUTPUT_SUBDOMAINS=""

RUN_DIR=false
RUN_SUBDOMAINS=false

declare -a dirs
declare -a subdomains

# Function: Print a help message.
usage() {
  echo "Fetches unique URLs from the Wayback Machine."
  echo ""
  echo "Usage: $0 [ -d DOMAIN ] [ -w ]"
  echo ""
  echo "Options:"
  echo "  -d, --domain      Domain to query (e.g., example.com)."
  echo "  -i, --input       File with list of domains to query."
  echo "  -o, --output      Output file."
  echo "  -od, --output-dirs      Output file for directories."
  echo "  -os, --output-subdomains      Output file for subdomains."
  echo "  -w, --wordlist    Wordlist file to use for directory enumeration."
  echo "  -rd, --run-dir    Run directory enumeration."
  echo "  -rs, --run-subdomains    Run subdomain enumeration."
  echo "  -h, --help        Display this help message."
  exit 1
}

exit_error() { # Function: Exit with error.
    usage
    echo "---------------" >&2
    echo "Exiting!" >&2
    exit 1
}

run_gobuster_dir() {
    local domain="$1"
    local wordlist="$2"

    # Command: gobuster dir -u https://example.com -w ~/Tools/SecLists-master/Discovery/Web-Content/dirsearch-wordlist.txt --no-color -e --hide-length --delay 1s -b "" -s 200 -q -n
    results=$(gobuster dir -u "$domain" -w "$wordlist" --no-color -e --hide-length --delay 500ms -b "" -s 200 -q -n)

    if [[ -n "$results" ]] # Check if results are empty or not.
    then
        dirs=("${dirs[@]}" "$results")
    fi
}

run_gobuster_dns() {
    local domain="$1"
    local wordlist="$2"

    # Command: gobuster dns --domain example.com -w ~/Tools/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt --no-color -q -d 1s --no-progress --no-error --wildcard | cut -d " " -f1
    # Has to be domain name with no http:// or https:// or else error returned that it couldn't validate base domain.

    # Output returned like: domain ip-address.
    # Couldn't find the flag to just print subdomains that were found.
    results=$(gobuster dns --domain "$domain" -w "$wordlist" --no-color -q -d 1s --no-progress --no-error --wildcard | cut -d " " -f1)

    if [[ -n "$results" ]] # Check if results are empty or not.
    then
        subdomains=("${subdomains[@]}" "$results")
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)
            INPUT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -od|--output-dirs)
            OUTPUT_DIRS="$2"
            shift 2
            ;;
        -os|--output-subdomains)
            OUTPUT_SUBDOMAINS="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -w|--wordlist)
            WORDLIST="$2"
            shift 2
            ;;
        -rd|--run-dir)
            RUN_DIR=true
            shift
            ;;        
        -rs|--run-subdomains)
            RUN_SUBDOMAINS=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if a file with domains or domain were inputted.
if [[ -z "$INPUT" && -z "$DOMAIN" ]]
then
    echo "[!]  Domain or input file is required" >&2
    echo "[*] Run with -h for help" >&2 # Probably redundant.
    echo "---------------" >&2
    exit_error
fi

# Check if wordlist was inputted and if the wordlist exists.
if [[ -z "$WORDLIST" || ! -f "$WORDLIST" ]]
then
    echo "[!] Wordlist not specified correctly and is required" >&2
    echo "[*] Run with -h for help" >&2 # Probably redundant.
    echo "---------------" >&2
    exit_error
fi

if [[ "$RUN_DIR" == true ]]
then
    if [[ -n "$INPUT" ]]
    then
        echo "[*] Getting all found directories for domains in file: $INPUT" >&2 # I suck with these sort of messages.
        echo "[*] Using wordlist: $WORDLIST" >&2
        while IFS= read -r domain # Read each line in the file.
        do
            echo "[*] Running gobuster on: $domain" >&2
            run_gobuster_dir "$domain" "$WORDLIST"

        done < "$INPUT"
    elif [[ -n "$DOMAIN" ]]
    then
        echo "[*] Getting all found directories for domain: "$DOMAIN"" >&2 # I suck with these sort of messages.
        echo "[*] Using wordlist: $WORDLIST" >&2
        run_gobuster_dir "$DOMAIN" "$WORDLIST"
    else
        echo "[!] Error: You must specify a domain (-d) or an input file (-i)." >&2
        exit_error
    fi

    if [[ -n "${dirs[@]}" ]]
    then

        if [[ -n "$OUTPUT" ]]
        then
            echo "[*] Saving results to file: $OUTPUT" >&2
            echo "${dirs[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT"
        elif [[ -n "$OUTPUT_DIRS" ]]
        then
            echo "[*] Saving results to file: $OUTPUT_DIRS" >&2
            echo "${dirs[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT_DIRS"
        else
            echo "" >&2
            echo "---------------" >&2
            echo "[*] Results: " >&2
            echo "---------------" >&2
            echo "${dirs[@]}" | tr ' ' '\n' | sort -u
            echo "---------------" >&2
            echo "" >&2
        fi
        
    fi
fi

if [[ "$RUN_SUBDOMAINS" == true ]]
then
    if [[ -n "$INPUT" ]]
    then
        echo "[*] Getting all suddomains for domains in file: $INPUT" >&2
        echo "[*] Using wordlist: $WORDLIST" >&2
        while IFS= read -r domain # Read each line in the file.
        do
            echo "[*] Running gobuster on: $domain" >&2
            run_gobuster_dns "$domain" "$WORDLIST"

        done < "$INPUT"
    elif [[ -n "$DOMAIN" ]]
    then
        echo "[*] Getting all subdomains for domain: "$DOMAIN"" >&2
        echo "[*] Using wordlist: $WORDLIST" >&2
        run_gobuster_dns "$DOMAIN" "$WORDLIST"
    else
        echo "[!] Error: You must specify a domain (-d) or an input file (-i)." >&2
        exit_error
    fi

    if [[ -n "${subdomains[@]}" ]]
    then
        if [[ -n "$OUTPUT" ]]
        then
            echo "[*] Saving results to file: $OUTPUT" >&2
            echo "${subdomains[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT"
        elif [[ -n "$OUTPUT_SUBDOMAINS" ]]
        then
            echo "[*] Saving results to file: $OUTPUT_SUBDOMAINS" >&2
            echo "${subdomains[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT_SUBDOMAINS"
        else
            echo "" >&2
            echo "---------------" >&2
            echo "[*] Results: " >&2
            echo "---------------" >&2
            echo "${subdomains[@]}" | tr ' ' '\n' | sort -u
            echo "---------------" >&2
            echo "" >&2
        fi
        
    fi
fi

echo "[*] Done!" >&2