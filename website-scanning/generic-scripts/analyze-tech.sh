#!/usr/bin/env bash

FILE=""
MIN_COUNT=5

usage() {
    echo "Usage: $0 [-f JSON_FILE] [-m MIN_COUNT] [-h]"
    echo "  -f    JSON file from httpx output"
    echo "  -m    Minimum occurrence to show (default: 5)"
    echo "  -h    Display help menu"
    1>&2
}

exit_error() {
    usage
    echo "--------------------------------------------------"
    echo "Exiting!"
    exit 1
}

while getopts "f:m:h" opt; do
    case ${opt} in
        f) FILE="${OPTARG}" ;;
        m) MIN_COUNT="${OPTARG}" ;;
        h|*) exit_error ;;
    esac
done

if [[ -z "$FILE" ]] || [[ ! -f "$FILE" ]]; then
    echo "[!] Error: Valid input file required."
    exit_error
fi

echo -e "\n\033[1;36m┌────────────────────────────────────────────────┐\033[0m"
echo -e "\033[1;36m│          HTTPX TECH STACK ANALYZER             │\033[0m"
echo -e "\033[1;36m└────────────────────────────────────────────────┘\033[0m"
echo -e "[*] Minimum threshold: \033[1;33m$MIN_COUNT\033[0m"

# Added amazon, fastly, imperva, stackpath to catch stragglers
CLOUD_PATTERN="cloud|aws|amazon|azure|google cloud|alibaba|digitalocean|linode|akamai|cloudflare|cdn|waf|s3|blob|bot|cdnjs|fastly|stackpath|imperva"

# --- Standard Web Technologies ---
echo -e "\n\033[1;32m[+] Standard Web Technologies\033[0m"
echo "┌─────────┬──────────────────────────────────────┐"
echo "│  COUNT  │ TECHNOLOGY                           │"
echo "├─────────┼──────────────────────────────────────┤"
# FIXES: 
# 1. jq: gsub("\n"; " ") replaces line breaks so "The Events Calendar" stays together
# 2. sed 's/:.*//g' brutally deletes the colon and EVERYTHING after it, fixing weird version formats
# 3. awk: substr($2, 1, 36) truncates long names so the right border │ never breaks
jq -r '.tech // [] | .[] | gsub("\n"; " ") | gsub("  +"; " ")' "$FILE" | \
    grep -viE "$CLOUD_PATTERN" | \
    sed 's/:.*//g' | \
    sort | uniq -c | sort -nr | \
    awk -v min="$MIN_COUNT" '$1 >= min { tech = substr($2, 1, 36); printf "│ \033[1;33m%7s\033[0m │ %-36s │\n", $1, tech }'
echo "└─────────┴──────────────────────────────────────┘"

# --- Cloud Infrastructure ---
echo -e "\n\033[1;35m[+] Cloud & Infrastructure\033[0m"
echo "┌─────────┬──────────────────────────────────────┐"
echo "│  COUNT  │ TECHNOLOGY                           │"
echo "├─────────┼──────────────────────────────────────┤"
jq -r '.tech // [] | .[] | gsub("\n"; " ") | gsub("  +"; " ")' "$FILE" | \
    grep -iE "$CLOUD_PATTERN" | \
    sed 's/:.*//g' | \
    sort | uniq -c | sort -nr | \
    awk -v min="$MIN_COUNT" '$1 >= min { tech = substr($2, 1, 36); printf "│ \033[1;33m%7s\033[0m │ %-36s │\n", $1, tech }'
echo "└─────────┴──────────────────────────────────────┘"

echo -e "\n\033[1;36m[*] Analysis Complete.\033[0m\n"
