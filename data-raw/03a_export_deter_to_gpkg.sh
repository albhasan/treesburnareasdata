#!/bin/bash
###############################################################################
# EXPORT DETER SHP TO GEOPACKAGE AND FIX THEIR POLYGONS.
# NOTE: Use deter_public_vis.gpkg for visualization ONLY!
###############################################################################


#---- Setup ----

# Path to the DETER file downloaded from TERRABRASILIS
DETER_SHP="/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp"

# Path to GRASS GIS database.
GRASS_DATA="/home/alber/Documents/grassdata"

# Path to results.
OUT_DETER="/home/alber/Documents/data/treesburnedareas/deter_public_vis.gpkg"
OUT_SUBAREAS="/home/alber/Documents/data/treesburnedareas/deter_subareas.gpkg"
SUBAREAS_LAYER=deter_subareas


#---- Utilitary functions ----

is_file_valid () {
    if [ -f "$1" ]; then
        echo "INFO: File found: $1"
    else
        echo "ERROR: Missing file: $1" >& 2
        exit 1
    fi
}

is_dir_valid () {
    if [ -d "$1" ]; then
        echo "INFO: Directory found: $GRASS_DATA"
    else
        echo "ERROR: Missing directory: $GRASS_DATA" >& 2
        exit 1
    fi
}


#---- Validation ----

if command -v ogr2ogr &> /dev/null; then
        echo "INFO: ogr2ogr found!"
    else
        echo "ERROR: ogr2ogr could not be found. Please install it." >& 2
        exit 1
fi

if command -v grass &> /dev/null; then
        echo "INFO: grass gis found!"
    else
        echo "ERROR: grass gis could not be found. Please install it." >& 2
        exit 1
fi

is_file_valid $DETER_SHP
is_dir_valid  $GRASS_DATA


#---- Import data to GeoPackage (only for qgis visualization) ----

ogr2ogr ${OUT_DETER} ${DETER_SHP}


#---- Import data to GRASS GIS ----

# NOTE: It seems GRASS GIS is better at this than QGIS.

# Create a GRASS location using DETER properties.
grass -e -c ${DETER_SHP} ${GRASS_DATA}/deter

# Import DETER data to GRASS GIS. GRASS cleans and intersects the polygons.
# NOTE: The snap argument was taken from GRASS suggestion during the first 
#       import. See the bottom of this file.
grass ${GRASS_DATA}/deter/PERMANENT --exec v.import input=${DETER_SHP} \
    output=deter_public snap=1e-06


#---- Export the results ----

grass ${GRASS_DATA}/deter/PERMANENT --exec v.out.ogr -a input=deter_public \
    type=area format=GPKG output=${OUT_SUBAREAS} output_layer=${SUBAREAS_LAYER}

exit 0

###############################################################################
# First  GRASS import, no snap
###############################################################################
# WARNING: The output contains topological errors:
#          Unable to calculate a centroid for 28413 areas
#                   Number of incorrect boundaries: 1335
#                            Number of duplicate centroids: 1
#                            The input could be cleaned by snapping vertices to each other.
#                            Estimated range of snapping threshold: [1e-13, 1e-05]
#                            Try to import again, snapping with 1e-09: 'snap=1e-09'
#                            Input </home/alber/Documents/data/deter/amazonia_legal/deter_public.shp>
#                            successfully imported without reprojection
#                            Execution of <v.import input=/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp output=deter_public> finished.
#                            Cleaning up default sqlite database ...
#                            Cleaning up temporary files...
#
###############################################################################
# Second GRASS import, snap=1e-09 (~ 1/10 of a milimeter).
###############################################################################
# 213390 areas represent multiple (overlapping) features, because polygons
# overlap in input layer(s). Such areas are linked to more than 1 row in
# attribute table. The number of features for those areas is stored as
# category in layer 2
# -----------------------------------------------------
# If overlapping is not desired, the input data can be cleaned by snapping
# vertices to each other.
# Estimated range of snapping threshold: [1e-13, 1e-05]
# Try to import again, snapping with 1e-08: 'snap=1e-08'
# Input </home/alber/Documents/data/deter/amazonia_legal/deter_public.shp>
# successfully imported without reprojection
# Execution of <v.import input=/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp output=deter_public snap=1e-09 --overwrite> finished.
# Cleaning up default sqlite database ...
# Cleaning up temporary files...
#
###############################################################################
# Third GRASS import, snap=1e-08 (~ 1 milimeter).
###############################################################################
# 204181 areas represent multiple (overlapping) features, because polygons
# overlap in input layer(s). Such areas are linked to more than 1 row in
# attribute table. The number of features for those areas is stored as
# category in layer 2
# -----------------------------------------------------
# If overlapping is not desired, the input data can be cleaned by snapping
# vertices to each other.
# Estimated range of snapping threshold: [1e-13, 1e-05]
# Try to import again, snapping with 1e-07: 'snap=1e-07'
# Input </home/alber/Documents/data/deter/amazonia_legal/deter_public.shp>
# successfully imported without reprojection
# Execution of <v.import input=/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp output=deter_public snap=1e-08 --overwrite> finished.
# Cleaning up default sqlite database ...
# Cleaning up temporary files...
#
###############################################################################
# Fourth GRASS import, snap=1e-07 (~ 1 centimeter).
############################################################################### 
# 204089 areas represent multiple (overlapping) features, because polygons
# overlap in input layer(s). Such areas are linked to more than 1 row in
# attribute table. The number of features for those areas is stored as
# category in layer 2
# -----------------------------------------------------
# If overlapping is not desired, the input data can be cleaned by snapping
# vertices to each other.
# Estimated range of snapping threshold: [1e-13, 1e-05]
# Try to import again, snapping with 1e-06: 'snap=1e-06'
# Input </home/alber/Documents/data/deter/amazonia_legal/deter_public.shp>
# successfully imported without reprojection
# Execution of <v.import input=/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp output=deter_public snap=1e-07 --overwrite> finished.
# Cleaning up default sqlite database ...
# Cleaning up temporary files...
#
###############################################################################
# Fifth GRASS import, snap=1e-06 (~ 10 centimeters).
############################################################################### 
# 203662 areas represent multiple (overlapping) features, because polygons
# overlap in input layer(s). Such areas are linked to more than 1 row in
# attribute table. The number of features for those areas is stored as
# category in layer 2
# -----------------------------------------------------
# If overlapping is not desired, the input data can be cleaned by snapping
# vertices to each other.
# Estimated range of snapping threshold: [1e-13, 1e-05]
# Try to import again, snapping with 1e-05: 'snap=1e-05'
# Input </home/alber/Documents/data/deter/amazonia_legal/deter_public.shp>
# successfully imported without reprojection
# Execution of <v.import input=/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp output=deter_public snap=1e-06 --overwrite> finished.
# Cleaning up default sqlite database ...
# Cleaning up temporary files...
#
###############################################################################
# Sixth GRASS import, snap=1e-05 (~ 1 meter).
############################################################################### 
# 203122 areas represent multiple (overlapping) features, because polygons
# overlap in input layer(s). Such areas are linked to more than 1 row in
# attribute table. The number of features for those areas is stored as
# category in layer 2
# -----------------------------------------------------
# If overlapping is not desired, the input data can be cleaned by snapping
# vertices to each other.
# Manual cleaning may be needed.
# Input </home/alber/Documents/data/deter/amazonia_legal/deter_public.shp>
# successfully imported without reprojection
# Execution of <v.import input=/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp output=deter_public snap=1e-05 --overwrite> finished.
# Cleaning up default sqlite database ...
# Cleaning up temporary files...
#
###############################################################################
# Seventh GRASS import, snap=1e-04 (~ 10 meters).
############################################################################### 
# 197545 areas represent multiple (overlapping) features, because polygons
# overlap in input layer(s). Such areas are linked to more than 1 row in
# attribute table. The number of features for those areas is stored as
# category in layer 2
# -----------------------------------------------------
# If overlapping is not desired, the input data can be cleaned by snapping
# vertices to each other.
# Manual cleaning may be needed.
# Input </home/alber/Documents/data/deter/amazonia_legal/deter_public.shp>
# successfully imported without reprojection
# Execution of <v.import input=/home/alber/Documents/data/deter/amazonia_legal/deter_public.shp output=deter_public snap=1e-04 --overwrite> finished.
# Cleaning up default sqlite database ...
# Cleaning up temporary files...
