#!/usr/bin/env bash

INPUTFILE=""
OUTPUTFILE=""

usage() {
  echo "Usage: $0 [ -f FILE OF CRAWLED URLS ]
        [ -o OUTPUT FILE (optional, defaults to stdout) ]
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
            INPUTFILE="${OPTARG}"
            ;;
        o)
            OUTPUTFILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
        :)
            echo "[!] Missing argument for -${OPTARG}" 1>&2
            exit_error
            ;;
        *)
            exit_error
            ;;
    esac
done

if [[ -z "$INPUTFILE" ]]
then
    echo "[!] Not all required arguments were supplied (-f is required)"
    echo "---------------"
    exit_error
    exit 1
fi

if [[ ! -f "$INPUTFILE" ]]
then
    echo "[!] Inputted file '$INPUTFILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

# High-value parameters likely to interact with DB queries
PARAM_REGEX='\?(id|uid|user_id|post_id|item_id|doc_id|ref|key|uuid|search|q|query|keyword|term|find|lookup|name|email|username|filter|category|cat|type|status|role|group|tag|author|brand|sort|order|orderby|sort_by|dir|column|col|limit|offset|page|start|end|count|date|from|to|year|month|draw|columns|p)='

# Handle stdout vs file output
if [[ -n "$OUTPUTFILE" ]]
then
    echo "[*] Extracting high-value SQLi parameters..."
    echo "---------------"
    # Clear the output file at the start so we append cleanly
    > "$OUTPUTFILE"

    # Grep the params, deduplicate, and save
    grep -iE "$PARAM_REGEX" "$INPUTFILE" | sort -u >> "$OUTPUTFILE" 2>/dev/null

    # Count results
    count=$(wc -l < "$OUTPUTFILE")

    echo "[*] Extraction complete. Found $count parameterized endpoints."
    echo "[*] Saved to: $OUTPUTFILE"
else
    # Grep the params and deduplicate
    results=$(grep -iE "$PARAM_REGEX" "$INPUTFILE" | sort -u 2>/dev/null)

  echo "$results"

fi
