#!/bin/bash
###############################################################################
# Download MCD64A1 
#------------------------------------------------------------------------------
# NOTE: 
# - earthdata_credentials.sh is a shell script that loads the Earth Data token
#   into the variable ED_TOKEN.
# - Run this script once a month.
###############################################################################

# Directory for storing the downloaded files.
OUT_DIR="${HOME}/data/mcd64a1"

# File with Earh Data credentials.
FILE=${HOME}/earthdata_credentials.sh

# Load Earth Data credentials from another file.
if [ -f "$FILE" ]; then
    source ${FILE}
else
    echo "ERROR: File with credentials not found: ${FILE}" && exit 1
fi
[ -d "${OUT_DIR}" ] || { echo "ERROR: Directory ${OUT_DIR} does not exist!" >&2; exit 1; }

# Load ED_TOKEN
source "${FILE}"

URL="https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MCD64A1/"

# Download data
wget -e robots=off -m -np -R .html,.tmp -nH --cut-dirs=3 "${URL}" --header \"Authorization: Bearer $ED_TOKEN\" -P "${OUT_DIR}"

exit 0
