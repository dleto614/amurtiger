#!/usr/bin/env bash

FILE=""

# The target list
techs=("wordpress" "drupal" "joomla" "asp" "lotus" "struts" "oracle" "cakephp" "codeigniter" "tomcat" "weblogic" "glassfish" "mikrotik" "cisco" "fortinet")

usage() {
  echo "Usage: $0 [ -f FILE OF DOMAINS ]
        [ -h HELP ]" 1>&2
}

exit_error() {
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

while getopts "f:h" opt
do
    case ${opt} in
        f)
            FILE="${OPTARG}"
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

if [[ ! -f "$FILE" ]]
then
    echo "[!] Inputted file '$FILE' does not exist"
    echo "---------------"
    exit_error
    exit 1
fi

# Extract just the filename (e.g., turns /home/alix/domains.log into domains.log)
BASENAME=$(basename "$FILE")

echo "[*] Starting automated tech discovery pipeline..."
echo "[*] Base output will be saved as: [tech]-${BASENAME}"
echo "---------------"

# Loop through each technology
for tech in "${techs[@]}"; do

    # Format the output filename (e.g., drupal-domains.log)
    HTTPX_OUT="${tech}-${BASENAME}"

    echo "[*] Discovering: $tech"
    echo "---------------"

    # Run httpx to filter for the tech
    ./run-httpx.sh -f "$FILE" -o "$HTTPX_OUT" -t "$tech"

    echo "[*] Finished discovering $tech"
    echo "---------------"
    echo ""
done

echo "[*] Discovery pipeline complete."
echo "[*] Review your [tech]-${BASENAME} files, then run Nuclei manually."
