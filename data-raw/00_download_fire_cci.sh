#!/usr/bin/env bash

###############################################################################
# Download ESA MODIS Fire_cci Burned Area data - Pixel product (only South 
# America)
#------------------------------------------------------------------------------
# NOTE: 
# - Run once a month!
###############################################################################

OUT_DIR="${HOME}/data/fire_cci"
[ -d "${OUT_DIR}" ] || { echo "ERROR: Directory ${OUT_DIR} does not exist!" >&2; exit 1; }

URL="https://dap.ceda.ac.uk/neodc/esacci/fire/data/burned_area/MODIS/pixel/v5.1/compressed/"

wget -e robots=off -m -np -R .html,.tmp -nH -U mozilla -nH --cut-dirs=4 -P "${OUT_DIR}" -t 5 -A '*AREA_2*.tar.gz' ${URL}
wget -e robots=off -m -np -R .html,.tmp -nH -U mozilla -nH --cut-dirs=4 -P "${OUT_DIR}" -t 5 -A '*.pdf'           ${URL}
wget -e robots=off -m -np -R .html,.tmp -nH -U mozilla -nH --cut-dirs=4 -P "${OUT_DIR}" -t 5 -A '*.txt'           ${URL}

exit 0
