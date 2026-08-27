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

 while getopts "f:n:o:h" opt
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
if [[ -z "$FILE" || -z "$OUTPUTFILE" ]]
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

# Now run subfinder
output=$(cat "$FILE" | subfinder -all -silent -nc | sort -u)

# Now remove bad domains that we don't want to scan or crawl
# Probably incomplete, but whatever...
# Now remove bad domains that we don't want to scan or crawl
echo "$output" | grep -Ev "innovationcast|blastheadrecords|cloudflare\.com|quorum|pantheonsite\.io|google\.com|wix\.com|wordpress\.com|microsoft\.com|incapsula\.com|bluehost\.com|certus|twitter\.com|facebook\.com|bit\.ly|x\.com|amazon\.com|yahoo\.com|youtube\.com|^$" | tee -a "$OUTPUTFILE"
