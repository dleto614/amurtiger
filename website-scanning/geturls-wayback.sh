#!/usr/bin/env bash

# TODO: Add output to file option.

# TODO: Figure out how to handle the jq output that fails.
# TODO: Probably will have to figure out a way to not timeout with requests.

# Probably should make it less verbose or at least handle how the terminal handles piped output.
# So that only the urls are piped through not the echo stuff.

DOMAIN=""

INPUT=""
OUTPUT=""

OUTPUT_URLS=""
OUTPUT_WAYBACK_URLS=""

GET_URLS=false
CREATE_WAYBACK_URLS=false
USE_HOST_WILDCARD=false

declare -a urls
declare -a wayback_urls

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
  echo "  -ou, --output-urls      Output file for URLs."
  echo "  -ow, --output-wayback-urls      Output file for Wayback Machine URLs."
  echo "  -w, --wildcard    Enable host wildcard (e.g., query '*.domain.com', not 'domain.com')."
  echo "  -gu, --get-urls   Get URLs from Wayback Machine."
  echo "  -cu, --create-wayback-urls   Create URLs from Wayback Machine."
  echo "  -h, --help        Display this help message."
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]
do
  case "$1" in
    -d|--domain) 
      DOMAIN="$2"; 
      shift 2 
      ;;
    -i|--input) 
      INPUT="$2"; 
      shift 2 
      ;;
    -o|--output) 
      OUTPUT="$2"; 
      shift 2 
      ;;
    -ou|--output-urls) 
      OUTPUT_URLS="$2"; 
      shift 2 
      ;;
    -ow|--output-wayback-urls) 
      OUTPUT_WAYBACK_URLS="$2"; 
      shift 2 
      ;;
    -w|--wildcard) 
      USE_HOST_WILDCARD=true; 
      shift 
      ;;
    -gu|--get-urls) 
      GET_URLS=true; 
      shift 
      ;;
    -cu|--create-wayback-urls) 
      CREATE_WAYBACK_URLS=true; 
      shift 
      ;;
    -h|--help) 
      usage 
      ;;
    *) 
      echo "Unknown option: $1" >&2; 
      usage 
      ;;
  esac
done

process_domain() {
  local domain="$1" # Handle the passed domain.

  if [[ "$USE_HOST_WILDCARD" == true ]]
  then
    URL="http://web.archive.org/cdx/search/cdx?url=*.$domain/*&fl=timestamp,original&output=json"
    pages=$(curl -s "http://web.archive.org/cdx/search/cdx?url=*.$domain/*&showNumPages=true")
  else
    URL="http://web.archive.org/cdx/search/cdx?url=$domain/*&fl=timestamp,original&output=json"
    pages=$(curl -s "http://web.archive.org/cdx/search/cdx?url=$domain/*&fl&showNumPages=true")
  fi

  echo "[*] Found $pages pages for: $domain" >&2

  # Check if pages variable is empty
  if [[ -z "$pages" ]]
  then
    echo "[!] No pages found for $domain" >&2
    return # Think should be a return?
  fi

  for page in $(seq 1 $pages)
  do
    echo "[*] Fetching page $page of $pages" >&2
    results=$(curl -s "$URL&page=$page")
    
    if [[ "$GET_URLS" == true ]]
    then
      final_urls=$(echo "$results" | jq -r '.[1:] | .[][1]')

      if [[ -n "$final_urls" ]]
      then
        urls=("${urls[@]}" "$final_urls")
      fi
    fi

    if [[ "$CREATE_WAYBACK_URLS" == true ]]
    then
      final_wayback_urls=$(echo "$results" | jq -r '.[1:] | .[] | "https://web.archive.org/web/\(.[0])/\(.[1])"')

      if [[ -n "$final_wayback_urls" ]]
      then
        wayback_urls=("${wayback_urls[@]}" "$final_wayback_urls")
      fi
    fi

    sleep 1
  done
}

if [[ -z "$DOMAIN" && -z "$INPUT" ]]
then
  echo "[!] Error: You must specify a domain (-d) or an input file (-i)." >&2
  usage
fi

if [[ "$INPUT" ]]
then
  echo "[*] Reading domains from file: $INPUT" >&2
  while IFS= read -r domain # Read each line in the file.
  do
    process_domain "$domain"
  done < "$INPUT"
elif [[ "$DOMAIN" ]]
then
  echo "[*] Processing domain: $DOMAIN" >&2
  process_domain "$DOMAIN"
else
  echo "[!] Error: You must specify a domain (-d) or an input file (-i)." >&2
  usage
fi

if [[ -n "${urls[@]}" ]]
then
  if [[ -n "$OUTPUT" ]]
  then
    # Save URLs to file
    echo "[*] Saving URLs to file: $OUTPUT" >&2
    echo "${urls[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT"
  elif [[ -n "$OUTPUT_URLS" ]]
  then
    # Save URLs to file
    echo "[*] Saving URLs to file: $OUTPUT_URLS" >&2
    echo "${urls[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT_URLS"
  else
    # Print all URLs and use sort -u to get unique values
    echo "[*] Found ${#urls[@]} unique URLs" >&2
    echo "---------------" >&2
    echo "[*] URLs: " >&2
    echo "---------------" >&2
    echo "${urls[@]}" | tr ' ' '\n' | sort -u
    echo "" >&2
    echo "---------------" >&2
  fi
fi

if [[ -n "${wayback_urls[@]}" ]]
then
  if [[ -n "$OUTPUT" ]]
  then
    # Save Wayback Machine URLs to file
    echo "[*] Saving Wayback Machine URLs to file: $OUTPUT" >&2
    echo "${wayback_urls[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT"
  elif [[ -n "$OUTPUT_WAYBACK_URLS" ]]
  then
    # Save Wayback Machine URLs to file
    echo "[*] Saving Wayback Machine URLs to file: $OUTPUT_WAYBACK_URLS" >&2
    echo "${wayback_urls[@]}" | tr ' ' '\n' | sort -u > "$OUTPUT_WAYBACK_URLS"
  else
    # Print all Wayback Machine URLs and use sort -u to get unique values
    echo "[*] Found ${#wayback_urls[@]} unique URLs" >&2
    echo "---------------" >&2
    echo "[*] Wayback Machine URLs: " >&2
    echo "---------------" >&2
    echo "${wayback_urls[@]}" | tr ' ' '\n' | sort -u
    echo "" >&2
    echo "---------------" >&2
  fi
fi