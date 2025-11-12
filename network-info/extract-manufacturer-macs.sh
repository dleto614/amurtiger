#!/usr/bin/env bash

# OUI database used: https://github.com/Ringmast4r/OUI-Master-Database

# TODO: Write the part where pcap can be read.

# This script takes in a list of MAC addresses and returns the manufacturer and ip address of the device

INTERFACE=""
JSON_FILE=""

INPUT=""
OUTPUT=""

usage() {  # Function: Print a help message.
    echo "Usage: $0 [ -i INTERFACE ] ]
        [ -f PCAP INPUT FILE ]
        [ -j JSON FILE WITH MANUFACTURES INFO BY MAC ADDRESS ] 
        [ -o OUTPUT FILE ] 
        [ -h HELP ]" 1>&2
}

exit_error() { # Function: Exit with error.
  usage
  echo "---------------"
  echo "Exiting!"
  exit 1
}

query_mac() {
    local mac="$1" # Assign the mac argument to a local variable.

    # Extract the OUI, which is the first three bytes (first 8 characters including colons)
    local oui="${mac:0:8}"
    oui="${oui^^}" # Capitalize to ensure we actually recieve results.

    # Get the full JSON object for the OUI
    result=$(jq --arg mac "$oui" '.[$mac]' "$JSON_FILE")

    # if [ -n "$result" ] && [ "$result" != "null" ]
    # then
        # echo "Manufacturer found: "
        echo "$result" | jq -r '.manufacturer // "Not Found"'
    # fi
}


while getopts "i:r:j:o:h" opt
do
    case ${opt} in
        i)
            INTERFACE="${OPTARG}"
            ;;
        r)
            INPUT="${OPTARG}"
            ;;
        j)
            JSON_FILE="${OPTARG}"
            ;;
        o)
            OUTPUT="${OPTARG}"
            ;;
        h)
            exit_error
            ;;
    esac
done

if [[ -z "$INTERFACE" || -z "$JSON_FILE" ]]
then

    echo "[!] Not all required arugments were supplied"
    echo "---------------"
    exit_error
    exit 1

fi

# Command: tshark -i wlan0 -T fields -e ip.src -e eth.src
tshark -i "$INTERFACE" -T fields -Y "eth and ip"  -e frame.time_epoch -e ip.src -e eth.src 2>/dev/null | while IFS=$'\t' read -r epoch_time ip_src mac_src; do

    if [[ -n "$epoch_time" && "$ip_src" && "$mac_src" ]]
    then
        # echo "[*] Found:  "$ip_src" "$mac_src""
        
        # echo "[*] Checking mac address."
        result=$(query_mac "$mac_src")

        if [[ -n "$result" && "$result" != "null" ]]
        then
            # echo "[*] Results: "$ip_src" "$mac_src" "$result""

            # Get timestamp
            timestamp=$(date -d "@$epoch_time" -u +"%Y-%m-%dT%H:%M:%SZ")

            # Construct the new, more compact JSON object
            json_object=$(jq -c -n \
                            --arg ip "$ip_src" \
                            --arg mac "$mac_src" \
                            --arg name "$result" \
                            --arg timestamp "$timestamp" \
                            '{timestamp: $timestamp, ip: $ip, mac: $mac, manufacturer_name: $name }')

            if [[ -n "$OUTPUT" ]]
            then
                echo "$json_object" >> "$OUTPUT"
            else
                echo "$json_object"
            fi

        fi
    fi

done

