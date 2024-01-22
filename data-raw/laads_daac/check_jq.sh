#!/bin/bash
###############################################################################
# Check if a command is available.
#------------------------------------------------------------------------------
# Taken from:
# https://raymii.org/s/snippets/Bash_Bits_Check_if_command_is_available.html
###############################################################################
command_exists() {
    # check if command exists and fail otherwise
    command -v "$1" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "I require $1 but it's not installed. Abort."
        exit 1
    fi
}

for COMMAND in "jq" "curl"; do
    command_exists "${COMMAND}"
done

exit 0
