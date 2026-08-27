#!/usr/bin/env bash

FILES=""
OUTPUTFILE=""

# Declare an empty array to store the inputted files so we can process them properly
declare -a files

usage() {  # Function: Print a help message.
  echo "Usage: $0 [ -f LIST OF FILES  ] 
        [ -o OUTPUT FILE ] 
        [ -h HELP ]" 1>&2
}

exit_error() { # Function: Exit with error.
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

 while getopts "f:n:p:o:h" opt
 do
	 case ${opt} in
		f)
			# echo "IP file: ${OPTARG}"
			FILES="${OPTARG}"
			;;
		o)
			# echo "Rustscan output file: ${OPTARG}"
			OUTPUTFILE="${OPTARG}"
			;;
		h)
			exit_error
			;;
	esac
done

if [[ -n "$FILES" ]]
then
    echo "[*] Processing files: $FILES"
    files=${FILES[@]}

    # Replace the comma in the array to space
    for i in "${!files[@]}"
    do
        files[$i]="${files[$i]//,/ }"
    done
else
    echo "[!] Not all required arugments were supplied"
    echo "---------------"
    exit_error
    exit 1
fi

# Run command:
# For some reason, cat throws an error when files is in double quotes.
output=$(cat ${files[@]} | sort -u) # Cat all files and filter out any duplicates.

if [[ -n "$OUTPUTFILE" ]]
then
    echo "$output" | tee -a "$OUTPUTFILE"
else
    echo "$output"
fi
