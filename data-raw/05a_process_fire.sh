#!/bin/bash
###############################################################################
# EXPORT FIRE SPOTS 
###############################################################################


# Path to fire data.
FIRE_DIR="/home/alber/Documents/data/queimadas/focos_queimadas/NPP-375"
OUT_DIR="/home/alber/Documents/data/treesburnedareas"

# Path to temporal directory.
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")

# Path to results.
OUT_GPKG="${OUT_DIR}/npp_375.gpkg"


#---- Utilitary functions ----

is_dir_valid () {
    if [ -d "$1" ]; then
        echo "INFO: Directory found: $1"
    else
        echo "ERROR: Missing directory: $1"
        exit 1
    fi
}

is_out_valid () {
    if [ -f "$1" ]; then
        echo "ERROR: Out file already exists: $1"
        exit 1
    fi
}

#---- Validation ----

if command -v ogr2ogr &> /dev/null; then
    echo "INFO: ogr2ogr found!" 
else
    echo "ERROR: ogr2ogr could not be found. Please install it."
    exit 1
fi

is_dir_valid "$TMP_DIR"
is_dir_valid "$FIRE_DIR"
is_out_valid "$OUT_GPKG"

#---- Process ----

# Merge the fire shapefiles downloaded from INPE's queimadas webpage.
find ${FIRE_DIR} -type f -iname "*.shp" \ 
    -exec ogr2ogr -update -append "${TMP_DIR}"/fire_spots.shp {} \ 
    -nln fire_spots \;

# Export SHP to GPKG.
ogr2ogr -f GPKG "${OUT_GPKG}" "${TMP_DIR}"/fire_spots.shp

exit 0
