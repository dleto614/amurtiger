#!/usr/bin/env bash

COMMAND_DIRECTORY=""

usage() {
  echo "Usage: $0 [ -d DIRECTORY CONTAINING COMMANDS ]
      [ -h HELP ]" 1>&2

}

exit_error() {
  usage
  echo "----------------"
  exit 1
}

while getopts "d:h" opt
do
  case ${opt} in
    d)
      COMMAND_DIRECTORY="${OPTARG}"
      ;;
    h)
      exit_error
      ;;
  esac
done

# Check if the command directory was passed.
if [[ -z "$COMMAND_DIRECTORY" ]]
then
  echo "[!] Error: You must specify the directory containing the commands"
  echo "-----------------"
  exit_error
  exit 1
fi

# Run find command to recursively loop through every file in the directory.
echo "[*] Running commands in files from directory: $COMMAND_DIRECTORY"
echo "-----------------------------"
echo ""

# I stole this like a good programmer.
# Source - https://stackoverflow.com/a/8512497
# Posted by Bennet Yee, modified by community. See post 'Timeline' for change history
# Retrieved 2026-08-30, License - CC BY-SA 4.0
find "$COMMAND_DIRECTORY" -type f -name '*.txt' -exec bash {} \;
