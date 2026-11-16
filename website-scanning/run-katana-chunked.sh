#!/usr/bin/env bash

set -euo pipefail

FILE=""
OUTPUTFILE=""

# These can be adjusted...
CHUNK=50
DEPTH=10
TIMEOUT=30
CONCURRENCY=5
RATELIMIT=15

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
        *)
            exit_error
            ;;
    esac
done

if [[ -z "$FILE" ]]
then
    echo "[!] Not all required arguments were supplied"
    echo "---------------"
    exit_error
fi

if [[ ! -f "$FILE" ]]
then
    echo "[!] Host file '$FILE' does not exist"
    echo "---------------"
    exit_error
fi

command -v katana >/dev/null 2>&1 || { echo "[!] katana not found in PATH" >&2; exit 1; }

echo "[*] Starting Katana crawl..." >&2

crawl_in_chunks() {
    # Build target list: strip CRs before deduplicating and drop blank lines...
    local -a targets=()
    mapfile -t targets < <(tr -d '\r' < "$FILE" | sed '/^[[:space:]]*$/d' | sort -u)
    local -i total=${#targets[@]}

    (( total > 0 )) || { echo "[!] no usable targets in $FILE" >&2; return 1; }

    echo "[*] $total targets, chunks of $CHUNK" >&2

    # Results go to the output file if given, otherwise straight to stdout.
    if [[ -n "$OUTPUTFILE" ]]
    then
        : > "$OUTPUTFILE"       # Truncate once, never again
        exec 3>>"$OUTPUTFILE"   # fd 3 = the file
    else
        exec 3>&1               # fd 3 = stdout
    fi

    # Our lovely katana command.
    local -a katana_cmd=(katana -d "$DEPTH" -timeout "$TIMEOUT" \
                         -kf all -c "$CONCURRENCY" -rl "$RATELIMIT" -silent -nc -ncb)

    local -i i=0 end=0 chunk_num=0 start=$SECONDS

    # Loop through and properly chunk everything.
    while (( i < total ))
    do
        end=$(( i + CHUNK > total ? total : i + CHUNK ))
        chunk_num=$(( chunk_num + 1 ))

        printf '[*] chunk %d (targets %d-%d / %d)\n' "$chunk_num" "$(( i + 1 ))" "$end" "$total" >&2

        # Pipe out the list to the katana command.
        printf '%s\n' "${targets[@]:i:CHUNK}" | "${katana_cmd[@]}" >&3 \
            || echo "[!] chunk $chunk_num failed, continuing" >&2

        i=$(( i + CHUNK ))
    done

    exec 3>&-

    if [[ -n "$OUTPUTFILE" ]]
    then
        printf '[*] done: %d lines -> %s (%ds elapsed)\n' \
            "$(wc -l < "$OUTPUTFILE")" "$OUTPUTFILE" "$(( SECONDS - start ))" >&2
    else
        printf '[*] done (%ds elapsed)\n' "$(( SECONDS - start ))" >&2
    fi
}

echo "[*] Starting Katana chunked crawl..."

crawl_in_chunks