#!/usr/bin/env bash

FILE=""
RULESFILE=""
OUTDIR=""
RESULTDIR=""
MIN_COUNT=10

# Get absolute path to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $0 [ -f HTTPX JSON FILE ]
            [ -r RULES YAML FILE ]
            [ -d COMMAND OUTPUT DIRECTORY ]
            [ -o RESULT OUTPUT DIRECTORY ]
            [ -m MIN COUNT (default: 10) ]
            [ -h HELP ]
EOF
}

exit_error() {
    usage
    echo "--------------------------------------------------"
    echo "Exiting!"
    exit 1
}

while getopts "f:r:d:o:m:h" opt; do
    case ${opt} in
        f) FILE="${OPTARG}" ;;
        r) RULESFILE="${OPTARG}" ;;
        d) OUTDIR="${OPTARG}" ;;
        o) RESULTDIR="${OPTARG}" ;;
        m) MIN_COUNT="${OPTARG}" ;;
        h|*) exit_error ;;
    esac
done

if [[ -z "$FILE" ]]; then
    echo "[!] HTTPX JSON file required (-f)"
    exit_error
fi

if [[ -z "$RULESFILE" ]]; then
    echo "[!] Rules YAML file required (-r)"
    exit_error
fi

if [[ ! -f "$FILE" ]]; then
    echo "[!] Input file '$FILE' does not exist"
    exit_error
fi

if [[ ! -f "$RULESFILE" ]]; then
    echo "[!] Rules file '$RULESFILE' does not exist"
    exit_error
fi

if ! command -v jq &> /dev/null; then
    echo "[!] 'jq' is required but not installed."
    exit_error
fi

if ! command -v yq &> /dev/null; then
    echo "[!] 'yq' is required but not installed."
    exit_error
fi

# Convert input file to absolute path
FILE="$(cd "$(dirname "$FILE")" 2>/dev/null && pwd)/$(basename "$FILE")"
RULESFILE="$(cd "$(dirname "$RULESFILE")" 2>/dev/null && pwd)/$(basename "$RULESFILE")"

# Get basename from input file for output naming
BASENAME=$(basename "$FILE" .json)
BASENAME="${BASENAME%.log}"

# Default severity for nuclei
DEFAULT_SEVERITY="critical,high"

# Create directories if needed
[[ -n "$OUTDIR" ]] && mkdir -p "$OUTDIR/extract" "$OUTDIR/nuclei" "$OUTDIR/katana" "$OUTDIR/urls"
[[ -n "$RESULTDIR" ]] && mkdir -p "$RESULTDIR"

echo ""
echo "ATTACK SURFACE PLANNER"
echo "======================="

# Build tech count map - first word only, count unique URLs
declare -A TECH_COUNTS
while IFS=$'\t' read -r tech count; do
    TECH_COUNTS["$tech"]=$((count))
done < <(jq -r '
    select(.tech != null) |
    .tech[] as $t |
    ($t | sub(":.*"; "") | split(" ")[0] | ascii_downcase) + "\t" + .url
' "$FILE" 2>/dev/null | sort -u | cut -f1 | sort | uniq -c | awk '{print $2 "\t" $1}')

# Print tech inventory
echo ""
echo "[+] Tech Inventory (min: $MIN_COUNT)"
for tech in "${!TECH_COUNTS[@]}"; do
    if [[ ${TECH_COUNTS[$tech]} -ge $MIN_COUNT ]]; then
        echo "  ${TECH_COUNTS[$tech]} - $tech"
    fi
done | sort -rn

skipped=0
for tech in "${!TECH_COUNTS[@]}"; do
    if [[ ${TECH_COUNTS[$tech]} -lt $MIN_COUNT ]]; then
        ((skipped++))
    fi
done
[[ $skipped -gt 0 ]] && echo "  ... $skipped below threshold skipped"

# Parse rules - batch by tool type
declare -A NUCLEI_BATCH_TECHS NUCLEI_BATCH_FLAGS
KATANA_TECHS=""

while IFS=$'\t' read -r tech tool flags; do
    if [[ "$tool" == "nuclei" ]]; then
        key="$flags"
        NUCLEI_BATCH_TECHS[$key]+="${NUCLEI_BATCH_TECHS[$key]:+,}$tech"
        NUCLEI_BATCH_FLAGS[$key]="$flags"
    else
        KATANA_TECHS+="${KATANA_TECHS:+,}$tech"
    fi
done < <(yq -r '.[] | [.tech, .tool, .flags] | @tsv' "$RULESFILE")

# Collect commands by type
extract_cmds=()
nuclei_cmds=()
katana_cmds=()

# Function to count URLs that would be extracted
count_urls() {
    local techlist="$1"
    jq -r --arg techlist "$techlist" '
        select(.tech != null) |
        select(.tech[] | . as $tech_item | any($techlist | ascii_downcase | split(",")[]; . as $search | ($tech_item | ascii_downcase | contains($search)))) |
        .url
    ' "$FILE" 2>/dev/null | sort -u | wc -l
}

# Process nuclei rules
for key in "${!NUCLEI_BATCH_TECHS[@]}"; do
    matched=""

    IFS=',' read -ra techs <<< "${NUCLEI_BATCH_TECHS[$key]}"

    for tech in "${techs[@]}"; do
        for t in "${!TECH_COUNTS[@]}"; do
            if [[ "${t,,}" == "${tech,,}" ]]; then
                if [[ ${TECH_COUNTS[$t]} -ge $MIN_COUNT ]]; then
                    matched+="${matched:+, }$tech"
                fi
                break
            fi
        done
    done

    [[ -z "$matched" ]] && continue

    # Count actual URLs that will be extracted
    total=$(count_urls "$matched")

    ((total == 0)) && continue

    # Generate filename
    IFS=', ' read -ra name_parts <<< "$matched"
    if [[ ${#name_parts[@]} -le 3 ]]; then
        filename=$(printf '%s' "${name_parts[*]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cs 'a-z0-9-' '-')
    else
        filename=$(printf '%s' "${name_parts[0]}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-')
        filename+="-plus-${#name_parts[@]}"
    fi
    filename="${filename%-}"

    flags="${NUCLEI_BATCH_FLAGS[$key]}"
    tags=$(echo "$flags" | grep -oP '\-t\s+\K[^ ]+' 2>/dev/null)
    severity=$(echo "$flags" | grep -oP '\-s\s+\K[^ ]+' 2>/dev/null)
    severity="${severity:-$DEFAULT_SEVERITY}"

    # Determine URL file path
    if [[ -n "$OUTDIR" ]]; then
        OUTDIR_ABS="$(cd "$OUTDIR" 2>/dev/null && pwd)"
        url_file="${OUTDIR_ABS}/urls/${filename}.txt"
    else
        url_file="/tmp/${filename}-${BASENAME}.txt"
    fi

    # Build extract command
    extract_cmd="${SCRIPT_DIR}/extract-urls-tech.sh -f \"$FILE\" -t \"${matched}\" -o \"$url_file\""
    extract_cmds+=("$extract_cmd")

    # Build nuclei scan command
    scan_cmd="${SCRIPT_DIR}/run-nuclei.sh -f \"$url_file\" -u \"${SCRIPT_DIR}/user-agent.json\" -t \"$tags\" -s \"$severity\""
    [[ -n "$RESULTDIR" ]] && {
        RESULTDIR_ABS="$(cd "$RESULTDIR" 2>/dev/null && pwd)"
        scan_cmd+=" -o \"${RESULTDIR_ABS}/${filename}-${BASENAME}.txt\""
    }

    nuclei_cmds+=("$scan_cmd")

    if [[ -n "$OUTDIR" ]]; then
        echo "$extract_cmd" > "$OUTDIR/extract/${filename}.txt"
        echo "$scan_cmd" > "$OUTDIR/nuclei/${filename}.txt"
        tech_count=${#name_parts[@]}
        [[ $tech_count -eq 1 ]] && tech_word="tech" || tech_word="techs"
        echo "  - ${filename} (${tech_count} ${tech_word}, ${total} urls)"
    fi
done

# Process katana rules
if [[ -n "$KATANA_TECHS" ]]; then
    matched=""

    IFS=',' read -ra techs <<< "$KATANA_TECHS"

    for tech in "${techs[@]}"; do
        for t in "${!TECH_COUNTS[@]}"; do
            if [[ "${t,,}" == "${tech,,}" ]]; then
                if [[ ${TECH_COUNTS[$t]} -ge $MIN_COUNT ]]; then
                    matched+="${matched:+, }$tech"
                fi
                break
            fi
        done
    done

    if [[ -n "$matched" ]]; then
        total=$(count_urls "$matched")

        if [[ $total -gt 0 ]]; then
            filename="katana-crawl"

            if [[ -n "$OUTDIR" ]]; then
                OUTDIR_ABS="$(cd "$OUTDIR" 2>/dev/null && pwd)"
                url_file="${OUTDIR_ABS}/urls/${filename}.txt"
            else
                url_file="/tmp/${filename}-${BASENAME}.txt"
            fi

            extract_cmd="${SCRIPT_DIR}/extract-urls-tech.sh -f \"$FILE\" -t \"$matched\" -o \"$url_file\""
            extract_cmds+=("$extract_cmd")

            scan_cmd="${SCRIPT_DIR}/run-katana.sh -f \"$url_file\""
            [[ -n "$RESULTDIR" ]] && {
                RESULTDIR_ABS="$(cd "$RESULTDIR" 2>/dev/null && pwd)"
                scan_cmd+=" -o \"${RESULTDIR_ABS}/${filename}-${BASENAME}.txt\""
            }

            katana_cmds+=("$scan_cmd")

            if [[ -n "$OUTDIR" ]]; then
                echo "$extract_cmd" > "$OUTDIR/extract/${filename}.txt"
                echo "$scan_cmd" > "$OUTDIR/katana/${filename}.txt"
                tech_count=${#techs[@]}
                [[ $tech_count -eq 1 ]] && tech_word="tech" || tech_word="techs"
                echo "  - ${filename} (${tech_count} ${tech_word}, ${total} urls)"
            fi
        fi
    fi
fi

# Output
echo ""

if [[ -n "$OUTDIR" ]]; then
    echo "[+] URL Extraction: ${OUTDIR}/extract/"
    echo "[+] Nuclei Scans:   ${OUTDIR}/nuclei/"
    echo "[+] Katana Scans:   ${OUTDIR}/katana/"
    echo "[+] URL Files:      ${OUTDIR}/urls/"
    [[ -n "$RESULTDIR" ]] && echo "[+] Results:        ${RESULTDIR}/"
else
    echo "[+] URL Extraction"
    for cmd in "${extract_cmds[@]}"; do
        echo "$cmd"
    done

    if [[ ${#nuclei_cmds[@]} -gt 0 ]]; then
        echo ""
        echo "[+] Nuclei Scans"
        for cmd in "${nuclei_cmds[@]}"; do
            echo "$cmd"
        done
    fi

    if [[ ${#katana_cmds[@]} -gt 0 ]]; then
        echo ""
        echo "[+] Katana Scans"
        for cmd in "${katana_cmds[@]}"; do
            echo "$cmd"
        done
    fi
fi

echo ""
