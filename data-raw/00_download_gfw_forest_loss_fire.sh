#!/bin/bash

###############################################################################
# Download GFW Global Forest Loss due to Fire
#------------------------------------------------------------------------------
# NOTE:
# - Run once a year.
###############################################################################

OUT_DIR="${HOME}/data/gfw_forest_loss_fire"
[ -d "${OUT_DIR}" ] || { echo "ERROR: Directory ${OUT_DIR} does not exist!" >&2; exit 1; }

URL="https://glad.umd.edu/users/Alexandra/Fire_GFL_data/"

wget -e robots=off -m -np -U mozilla -nH --cut-dirs=4 -P "${OUT_DIR}" -t 5 -A 'LAM_fire_forest_loss_*.tif' ${URL}

exit 0
