#!/usr/bin/env bash

FILE=""
OUTPUTFILE=""
TAGS=""
SEVERITY=""
USER_AGENTS_FILE=""

# To store the tags and severity inputted as arrays
# so they would be in the proper format which is "whatever,something,etc..."
declare -a tags
declare -a severity

# Declare empty user agent variable to store the randomly selected value later.
user_agent=""

usage() {  # Function: Print a help message.
  echo "Usage: $0 [ -f FILE OF DOMAINS TO SCAN ]
        [ -o OUTPUT FILE TO SAVE RESULTS (OPTIONAL) ]
        [ -t TAGS TO USE (eg -t sqli,cve,...) (OPTIONAL) ]
        [ -s SEVERITY OF TAGS TO USE (eg -s high,medium,low) (OPTIONAL) ]
        [ -u USER AGENT FILE TO USE (OPTIONAL) ] 
        [ -h HELP ]" 1>&2
}

exit_error() { # Function: Exit with error.
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

while getopts "f:o:t:s:u:h" opt
do
    case ${opt} in
        f)
            echo "Domain file to parse: ${OPTARG}"
            FILE="${OPTARG}"
            ;;
        o)
            echo "Output file to save results in: ${OPTARG}"
            OUTPUTFILE="${OPTARG}"
            ;;
        t)
            echo "Tags to use: ${OPTARG}"
            TAGS="${OPTARG}"
            ;;
        s)
            echo "Severity to use: ${OPTARG}"
            SEVERITY="${OPTARG}"
            ;;
        u)
            echo "User agent file to use: ${OPTARG}"
            USER_AGENTS_FILE="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
    esac
done

if [[ -z "$FILE" ]]
then
    echo "[!] Not all required arugments were supplied"
    echo "---------------"
    exit_error
    exit 1
fi

# Check if file exists
if [[ ! -f "$FILE" ]]
then
    echo "[!] Inputted file '$FILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

if [[ -n "$USER_AGENTS_FILE" ]]
then
    echo "[*] Using supplied user agent file: $USER_AGENTS_FILE"
    echo "[*] Randomly selecting a user agent"
    echo "---------------"
    user_agent="User-Agent: "$(jq -r '.[]' "$USER_AGENTS_FILE" | shuf -n 1)

    echo "[*] Using user agent: "\"$user_agent"\""
    echo "---------------"
fi

# Check if TAGS and/or SEVERITY were inputted
# Assign to the correct array variable

# If both TAGS and SEVERITY were inputted:
if [[ -n "$TAGS" && -n "$SEVERITY" ]]
then
    echo "[*] Using supplied tags: $TAGS"
    echo "[*] Using supplied severity: $SEVERITY"
    echo "---------------"
    tags=${TAGS[@]}
    severity=${SEVERITY[@]}

    if [[ -n "$OUTPUTFILE" && -n "$USER_AGENTS_FILE" ]]
    then
        echo "[*] Running with tags, severity and user agent supplied, but with output file supplied to write results to."
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -tags "${tags[@]}" -s "${severity[@]}" -l "$FILE" -o "$OUTPUTFILE"
    elif [[ -z "$USER_AGENTS_FILE" && -z "$OUTPUTFILE" ]]
    then
        echo "[*] Running with tags and severity, but with no user agent supplied and no output file to write results to."
        nuclei -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -tags "${tags[@]}" -s "${severity[@]}" -l "$FILE"
    else # This might be a point of failure
        echo "[*] Running with tags and severity and user agent supplied, but no output file to write results to."
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -tags "${tags[@]}" -s "${severity[@]}" -l "$FILE"
    fi
# If only TAGS were inputted:
elif [[ -n "$TAGS" ]]
then
    echo "[*] Using supplied tags: $TAGS"
    echo "---------------"
    tags=${TAGS[@]}

    if [[ -n "$OUTPUTFILE" && -n "$USER_AGENTS_FILE" ]]
    then
        echo "[*] Running with tags and user agent supplied, but with output file supplied to write results to."
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -tags "${tags[@]}" -l "$FILE" -o "$OUTPUTFILE"  
    elif [[ -z "$USER_AGENTS_FILE" && -z "$OUTPUTFILE" ]]
    then
        echo "[*] Running with tags, but no user agent supplied and no output file supplied to write results to."
        nuclei -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -tags "${tags[@]}" -l "$FILE"
    else
        echo "[*] Running with tags and user agent supplied, but no output file supplied to write results to."
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -tags "${tags[@]}" -l "$FILE"
    fi
# If only SEVERITY were inputted:
elif [[ -n "$SEVERITY" && -n "$USER_AGENTS_FILE" ]]
then
    echo "[*] Using supplied severity and no tags: $SEVERITY"
    echo "---------------"
    severity=${SEVERITY[@]}

    if [[ -n "$OUTPUTFILE" && -n "$USER_AGENTS_FILE" ]]
    then
        echo "[*] Running with severity and user agent supplied, but with output file supplied to write results to."
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -s "${severity[@]}" -l "$FILE" -o "$OUTPUTFILE"
    elif [[ -z "$USER_AGENTS_FILE" && -z "$OUTPUTFILE" ]]
    then
        echo "[*] Running with severity, but with no user agent supplied and no output file to write results to."
        nuclei -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -s "${severity[@]}" -l "$FILE"
    else # This might be a point of failure
        echo "[*] Running with severity and user agent supplied, but no output file to write results to."
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -s "${severity[@]}" -l "$FILE"
    fi
else
    if [[ -n "$OUTPUTFILE" && -n "$USER_AGENTS_FILE" ]]
    then
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -l "$FILE" -o "$OUTPUTFILE"
    elif [[ -z "$USER_AGENTS_FILE" && -z "$OUTPUTFILE" ]]
    then
        nuclei -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -l "$FILE"
    else
        nuclei -H "$user_agent" -nmhe -nh -c 5 -bs 3 -rl 15 -timeout 30 -ss host-spray -l "$FILE"
    fi
fi
