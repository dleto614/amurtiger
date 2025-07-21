#!/usr/bin/env bash

FILE=""
OUTPUTFILE=""

usage() {  # Function: Print a help message.
  echo "Usage: $0 [ -f FILE OF DOMAINS  ] 
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
			FILE="${OPTARG}"
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

# Check if arguments were inputted
if [[ -z "$FILE" ]]
then
	echo "[!] Not all required arugments were supplied"
	echo "---------------"
	exit_error
	exit
fi

# Check if file exists
if [[ ! -f "$FILE" ]]
then
	echo "[!] Host file '$FILE' does not exist"
	echo "---------------"
	exit_error
	exit 1
fi

# Now run httprobe

output=$(cat "$FILE" | httprobe -c 5) # Concurrency is set to 5

if [[ -n "$OUTPUTFILE" ]]
then
    echo "$output" | tee -a "$OUTPUTFILE"
else
    echo "$output"
fi