#!/usr/bin/env bash

DOMAIN=""
INPUT=""
OUTPUT=""
LOGFILE=""
WORDLIST=""
DONE_FILE=""

WORKERS=10          # Number of targets to scan in parallel per block.
GOB_THREADS=5       # Gobuster threads per target.
STATUSES="200,302"  # Positive status codes to keep.
DELAY="150ms"       # Per-thread wait between requests. ~15-30 req/s per host at -T 10.
TIMEOUT="15s"       # Gobuster request timeout. Completeness over speed.

# The lovely usage message... thingie magiber...
usage() {
    echo "Runs gobuster in parallel over one target or a list of targets."
    echo "Results go to stdout or -o (appended). Status messages go to stderr or -l."
    echo ""
    echo "Usage: $0 [ -d DOMAIN | -i INPUT ] -w WORDLIST [ -o OUTPUT ] [ -l LOGFILE ]"
    echo ""
    echo "Options:"
    echo "  -d, --domain      Domain to query (must include http:// or https:// from httpx)."
    echo "  -i, --input       File with list of targets to query (expects http/https schemes from httpx)."
    echo "  -o, --output      Output file for results (appended, deduped at end of run)."
    echo "  -l, --log         Log file for status messages and errors."
    echo "  -w, --wordlist    Wordlist file to use for enumeration."
    echo "  -df, --done-file  File of already-scanned targets to skip (resume support)."
    echo "  -s, --statuses    Positive status codes to keep (default: 200,302)."
    echo "  -t, --workers     Number of targets scanned in parallel per block (default: 10)."
    echo "  -T, --threads     Gobuster threads per target (default: 5)."
    echo "      --timeout     Gobuster request timeout (default: 15s)."
    echo "      --delay       Per-thread delay between requests (default: 150ms, 0s to disable)."
    echo "  -h, --help        Display this help message."
    exit 1
}

exit_error() { # Exit with error.
    usage
    echo "---------------" >&2
    echo "Exiting!" >&2
    exit 1
}

# Log a status message or error to the log file or stderr.
log() {

    if [[ -n "$LOGFILE" ]]
    then
        printf '%s\n' "$1" >> "$LOGFILE"
    else
        printf '%s\n' "$1" >&2
    fi
}

# Print results to stdout or append them to the output file.
save_results() {
    local results="$1"

    if [[ -n "$results" ]] # Check if results are empty or not.
    then
        if [[ -n "$OUTPUT" ]]
        then
            printf '%s\n' "$results" >> "$OUTPUT"
        else
            printf '%s\n' "$results"
        fi
    fi
}

# Run gobuster in dir mode on a target.
run_gobuster_dir() {
    local url="$1" # Target already carries a scheme from httpx.

    log "[*] Running gobuster on: $url"

    # Command: gobuster dir -u https://example.com -w wordlist.txt --no-color -e --hide-length -b "" -s 200,302 -q -n -k --no-progress --no-error
    # -e expanded prints full URLs one per line (ready for gowitness), -n hides status codes,
    # -k skips TLS certificate validation, -s only keeps the status codes we care about.
    # -b "" is required: in gobuster 3.8.x the blacklist defaults to 404 and would override -s.
    # --random-agent: never announce "gobuster/x.x" in logs, pick a browser-ish UA instead.
    results=$(gobuster dir -u "$url" -w "$WORDLIST" -t "$GOB_THREADS" -s "$STATUSES" -b "" -e --no-color -q --no-progress --no-error --random-agent --retry -k ${TIMEOUT:+--timeout "$TIMEOUT"} ${DELAY:+--delay "$DELAY"} 2>/dev/null)

    if [[ -z "$results" ]] # Check if results are empty or not. Redundant, but might as well do it here for now.
    then
        log "[!] Nothing found for $url"
    else
        save_results "$results"
    fi
}

# Run gobuster on a target and mark it as done.
run_gobuster() {
    run_gobuster_dir "$1"

    if [[ -n "$DONE_FILE" ]]
    then
        printf '%s\n' "$1" >> "$DONE_FILE"
    fi
}

# Check if gobuster is installed.
if ! command -v gobuster > /dev/null 2>&1
then
    echo "[!] Gobuster not found in PATH" >&2
    echo "---------------" >&2
    exit_error
fi

# Check our arguments...
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
        -l|--log)
            LOGFILE="$2"
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
        -df|--done-file)
            DONE_FILE="$2"
            shift 2
            ;;
        -s|--statuses)
            STATUSES="$2"
            shift 2
            ;;
        -t|--workers)
            WORKERS="$2"
            shift 2
            ;;
        -T|--threads)
            GOB_THREADS="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --delay)
            DELAY="$2"
            shift 2
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
    echo "[!] Domain or input file is required" >&2
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
    echo ""
    exit_error
fi

# Check if input file exists.
if [[ -n "$INPUT" && ! -f "$INPUT" ]]
then
    echo "[!] Input file not found: $INPUT" >&2
    echo "---------------" >&2
    exit 1 # Exit.
fi

# Results append across runs so a restart never loses found URLs,
# the sort -u at the end of each completed run keeps the file clean.
if [[ -n "$OUTPUT" ]]
then
    log "[*] Appending results to file: $OUTPUT"
fi

# Make sure the done file exists so the skip check always works.
if [[ -n "$DONE_FILE" ]]
then
    log "[*] Resume enabled, skipping targets already in: $DONE_FILE"
    touch "$DONE_FILE"
fi

if [[ -n "$INPUT" ]]
then
    log "[*] Getting all found directories for targets in file: $INPUT"
    log "[*] Using wordlist: $WORDLIST"
    log "[*] Running $WORKERS targets per block with $GOB_THREADS gobuster threads each"

    count=0

    while IFS= read -r raw || [[ -n "$raw" ]] # Read each line in the file.
    do
        target="$(printf '%s' "$raw" | tr -d '[:space:]')"

        if [[ -z "$target" ]]
        then
            continue # Skip empty lines.
        fi

        case "$target" in \#*) continue ;; esac # Skip comment lines.

        # Skip bare domains or lines missing proper HTTP/HTTPS schemes (expected from a tool like httpx).
        if [[ "$target" != http://* && "$target" != https://* ]]
        then
            log "[!] Skipping (bare domain / missing scheme): $target"
            continue
        fi

        # Skip targets that were already scanned in a previous run.
        if [[ -n "$DONE_FILE" ]] && grep -qxsF "$target" "$DONE_FILE"
        then
            log "[*] Skipping (already done): $target"
            continue
        fi

        run_gobuster "$target" &

        ((count++))

        # Check if count is divisible by WORKERS via modulus.
        if [ $((count % WORKERS)) -eq 0 ]
        then
            log "[*] Reached maximum of $WORKERS targets running in the background"
            log "[*] Waiting for them to finish before starting the next block"
            wait # Wait for the current background processes to finish running before continuing.
        fi

    done < "$INPUT"

    wait # Wait for the last background processes to finish running.
elif [[ -n "$DOMAIN" ]]
then
    log "[*] Getting all found directories for target: $DOMAIN"
    log "[*] Using wordlist: $WORDLIST"

    target="$(printf '%s' "$DOMAIN" | tr -d '[:space:]')"

    # Ensure single domain target has a valid scheme.
    if [[ "$target" != http://* && "$target" != https://* ]]
    then
        echo "[!] An error occured with the scheme."
        echo "[*] If log specified, Check the logfile for the error message."
        log "[!] Error: Target '$DOMAIN' is a bare domain or missing a valid scheme (http:// or https://)."
        exit 1
    fi

    if [[ -n "$target" ]]
    then
        run_gobuster "$target" # Single target mode skips the done-file check on purpose.
    else
        echo "[!] An error occured with specifying the domain."
        echo "[*] If log specified, Check the logfile for the error message."
        log "[!] Error: Target domain cannot be empty."
        echo ""
        echo "---------------------------------------------------"
        exit_error
    fi
else
    echo "[!] An error occured with incorrect arguments either being inputted or not at all."
    echo "[*] If log specified, Check the logfile for the error message."
    log "[!] Error: You must specify a domain (-d) or an input file (-i)."
    echo ""
    echo "---------------------------------------------------"
    exit_error
fi

# Remove duplicate entries from the output file if one was given.
if [[ -n "$OUTPUT" ]]
then
    log "[*] Removing duplicate entries from: $OUTPUT"
    sort -u -o "$OUTPUT" "$OUTPUT"
fi

log "[*] Done!"