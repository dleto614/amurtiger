#!/usr/bin/env bash

# TODO: Later can add json output.

DOMAIN=""
INPUT=""
OUTPUT=""
WORDLIST=""

RUN_HTTPX=false
SAVE_HTTPX_DETAILS=false
SAVE_HTTPX_URLS=false

HTTPX_DETAILS_OUTPUT="" # For full httpx output
HTTPX_URLS_OUTPUT=""    # For clean list of URLs

# To store the domains after ffuf and concatenation
declare -a domains
domains=() # Probably unnecessary.

usage() {  # Function: Print a help message.
    echo "Usage: $0 [ -i FILE OF DOMAINS TO FUZZ ] 
        [ -o OUTPUT FILE FOR RAW SUBDOMAINS ]
        [ -d DOMAIN TO FUZZ ]
        [ -w WORDLIST FILE ]
        [ -hx RUN HTTPX ON FOUND SUBDOMAINS ]
        [ -shd FILE SAVE DETAILED HTTPX RESULTS ]
        [ -shu FILE SAVE CLEAN LIST OF LIVE URLS ]
        [ -h HELP ]" 1>&2
}

exit_error() { # Function: Exit with error.
  usage
  echo "---------------" >&2
  echo "Exiting!" >&2
  exit 1
}

run_ffuf() {
    local domain="$1"
    local base_domain="$2"
    local wordlist="$3"
    
    echo "[*] Fuzzing domain: $domain" >&2
    
    results=$(ffuf -u "$domain" \
        -H "Host: FUZZ.$base_domain" \
        -w "$wordlist" \
        -mc 200,302 \
        -ac \
        -t 20 \
        -p 0.1 \
        -s)
    
    echo "$results"
}

run_httpx() {
    local domains_array=("$@")
    
    echo "[*] Running httpx on domains..." >&2
    http_results=$(printf "%s\n" "${domains_array[@]}" | httpx  -silent -follow-redirects -status-code -title)

    if [[ -z "$http_results" ]]
    then
        echo "[!] No results were found with httpx." >&2
        echo "---------------" >&2
        return 1
    fi

    # Save the httpx results if output file is set.
    if [[ "$SAVE_HTTPX_DETAILS" == true && -n "$HTTPX_DETAILS_OUTPUT" ]]
    then
        echo "[*] Saving detailed httpx results to $HTTPX_DETAILS_OUTPUT" >&2
        echo "$http_results" >> "$HTTPX_DETAILS_OUTPUT"
    fi

    final_results=$(echo "$http_results" | grep -oE 'https?://[^ ]+')

    if [[ -n "$final_results" ]]
    then
        echo "" >&2
        echo "---------------" >&2
        echo "[*] Results: " >&2
        echo "---------------" >&2
        echo "$final_results"
        echo "" >&2

        # Save the urls from httpx if output file is set.
        if [[ "$SAVE_HTTPX_URLS" == true && -n "$HTTPX_URLS_OUTPUT" ]]
        then
            echo "[*] Saving live URLs to $HTTPX_URLS_OUTPUT" >&2
            echo "$final_results" >> "$HTTPX_URLS_OUTPUT"
        fi
    fi
    echo "---------------" >&2
    
    return 0
}

process_domain() {
    local domain="$1"
    local wordlist="$2"
    
    echo "" >&2
    echo "[*] Checking domain with httpx..." >&2
    resolved_domain=$(echo "$domain" | httpx -silent)

    if [[ -z "$resolved_domain" ]]
    then
        echo "[!] httpx failed to resolve: $domain" >&2
        echo "---------------" >&2
        return 1
    fi

    results=$(run_ffuf "$resolved_domain" "$domain" "$wordlist")
    
    if [[ -z "$results" ]]
    then
        echo "[!] No results found for $domain" >&2
        echo "---------------" >&2
        return 1
    fi

    echo "" >&2
    echo "---------------" >&2
    echo "[*] FFuF has found the following subdomains: " >&2
    echo "---------------" >&2

    while read -r subdomain
    do
        echo "$subdomain.$domain"
        domains=("${domains[@]}" "$subdomain.$domain")
    done <<< "$results"

    echo "" >&2
    echo "---------------" >&2
    
    return 0
}

process_input_file() {
    local input_file="$1"
    local wordlist="$2"
    
    echo "[*] Reading domains from file: $input_file" >&2

    while read -r domain
    do
        process_domain "$domain" "$wordlist"
    done < "$input_file"
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
    -d|--domain)
      DOMAIN="$2"
      shift 2
      ;;
    -w|--wordlist)
      WORDLIST="$2"
      shift 2
      ;;
    -hx|--run-httpx)
      RUN_HTTPX=true
      shift
      ;;
    -shd|--save-httpx-details)
      SAVE_HTTPX_DETAILS=true
      HTTPX_DETAILS_OUTPUT="$2"
      shift 2
      ;;
    -shu|--save-httpx-urls)
      SAVE_HTTPX_URLS=true
      HTTPX_URLS_OUTPUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit_error
      ;;
  esac
done

if [[ -z "$INPUT" && -z "$DOMAIN" ]]
then
    echo "[!]  Domain or input file is required" >&2
    echo "[*] Run with -h for help" >&2
    echo "---------------" >&2
    exit_error
fi

if [[ -z "$WORDLIST" || ! -f "$WORDLIST" ]]
then
    echo "[!] Wordlist not specified correctly and is required" >&2
    echo "[*] Run with -h for help" >&2
    echo "---------------" >&2
    exit_error
fi

# Process either a single domain or a file of domains
if [[ -n "$INPUT" ]]
then
    process_input_file "$INPUT" "$WORDLIST"
else
    process_domain "$DOMAIN" "$WORDLIST"
fi

# Save raw subdomains to the output file at the very end.
if [[ -n "$OUTPUT" && ${#domains[@]} -gt 0 ]]
then
    echo "[*] Appending found subdomains to $OUTPUT" >&2
    printf "%s\n" "${domains[@]}" >> "$OUTPUT"
fi

# Run httpx on found domains if requested
if [[ "$RUN_HTTPX" == true && ${#domains[@]} -gt 0 ]]
then
    run_httpx "${domains[@]}"
fi

echo "Done!" >&2