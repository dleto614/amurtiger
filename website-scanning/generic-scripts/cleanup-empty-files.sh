#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 -d DIRECTORY"
    exit 1
}

directory=""

while getopts ":d:h" opt; do
    case "$opt" in
        d)
            directory="$OPTARG"
            ;;
        h)
            usage
            ;;
        :)
            echo "Error: option -$OPTARG requires an argument." >&2
            usage
            ;;
        \?)
            echo "Error: invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

# Check that -d was provided
if [[ -z "$directory" ]]; then
    echo "Error: directory is required." >&2
    usage
fi

# Check that the path exists and is a directory
if [[ ! -d "$directory" ]]; then
    echo "Error: not a valid directory: $directory" >&2
    exit 1
fi

# Delete empty regular files
find "$directory" -type f -empty -print -delete

