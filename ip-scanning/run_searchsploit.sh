#!/usr/bin/env bash

FILE=""
OUTPUTFILE=""

usage() {  # Function: Print a help message.
  echo "Usage: $0 [ -f FILE OF NMAP RESULTS IN XML FORMAT ]
        [ -o OUTPUT FILE TO SAVE RESULTS (OPTIONAL) ] 
        [ -h HELP ]" 1>&2
}

exit_error() { # Function: Exit with error.
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

while getopts "f:o:h" opt
do
    case ${opt} in
        f)
            echo "Nmap file to parse: ${OPTARG}"
            FILE="${OPTARG}"
            ;;
        o)
            echo "Output file to save results in: ${OPTARG}"
            OUTPUTFILE="${OPTARG}"
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
	echo "[!] Host file '$HOSTFILE' does not exist"
	echo "---------------"
	exit_error
	exit 1
fi

if [[ -f "$OUTPUTFILE" ]]
then
  echo "[!] Output file '$OUTPUTFILE' already exists"
  echo "---------------"
  exit_error
  exit 1
fi

# TODO: Try to reduce verbose or at least add an option to be quiet or write to a logfile

# This is fucking art
while IFS= read -r line
do
  
  # Grep the ip address
  # Grep for "Ports:" first because in the output, the ip address is there twice
  # First one has the ip address and "Status" so to avoid duplication, grep for "Ports:"
  ip=$(echo "$line" | grep "Ports: " | grep -aEo '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')

  # Array to store the services that are found via the regex
  declare -a lookup_array
  mapfile -t lookup_array < <(echo "$line" | grep -oP '(?<=Ports: ).*' | grep -oP '//\K[^/]*(?=\/$)')

  for lookup in "${lookup_array[@]}"
  do

    if [[ -n "$lookup" ]]
    then

      # Ripped this regex originally from the searchsploit script
      # This way it filters out generic services like nginx
      version=$(echo "$lookup" | perl -ne 'print join "\n", $& while /\b\d+(?:\.\d+)*(?:[a-zA-Z]+)?\b/g')

      if [[ -n "$version" ]]
      then

        echo "[*] Valid input!"
        echo "[*] Searching '$lookup' on searchsploit"
        echo "---------------"

        # searchsploit --exclude="/dos/" -v -j "$lookup" | jq | tee -a searchsploit_results.json

        exploitdb_lookup=$(searchsploit --exclude="/dos/" -j "$lookup")

        # A little jq fuckery.
        # Check if the 'RESULTS_EXPLOIT' array is empty or not.
        # Since null is not used, had to check the length.
        check_results=$(jq '.RESULTS_EXPLOIT | select (. | length > 0)' <<< "$exploitdb_lookup")

        # Check if true or not.
        if [[ -n "$check_results" ]]
        then

          echo "[*] Results found for '$lookup'!"
          echo "---------------"

          # Add the ip address to the json.
          # I want the ip address to be the first key in the json array or whatever this is.
          if [[ -n "$OUTPUTFILE" ]] # Check if outputfile was supplied
          then
            jq '{IP: "'$ip'"} + . | .' <<< "$exploitdb_lookup" >> "$OUTPUTFILE"
          else
            jq '{IP: "'$ip'"} + . | .' <<< "$exploitdb_lookup"
            echo "---------------"
          fi 

          # Leaving the shellcode results as is. Not really a focus.
        
        fi
        
      fi

    fi
  done

done < "$FILE"

echo "Done with file '$FILE'!"