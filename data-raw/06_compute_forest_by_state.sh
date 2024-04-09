#!/bin/bash
###############################################################################
# COMPUTE THE AMAZON FOREST MASK AREA IN EACH BRAZILIAN STATE
###############################################################################



#---- Utilitary functions ----

logit() {
    echo "[`date +"%Y-%m-%d %T"`] - ${*}" 
    echo "[`date +"%Y-%m-%d %T"`] - ${*}" >> ${LOGFILE}
}

is_file_valid () {
    if [ -f "$1" ]; then
        logit "INFO: File found: $1"
    else
        logit "ERROR: Missing file: $1"
        exit 1
    fi
}

is_dir_valid () {
    if [ -d "$1" ]; then
        logit "INFO: Directory found: $1" 
    else
        logit "ERROR: Missing directory: $1"
        exit 1
    fi
}



#---- Setup ----

LOGFILE="compute_forest_by_state.log"

logit "================================================================"
logit "PROCESS FOREST MASKS"                 
logit "================================================================"

# Input
STATES_GPKG="/home/${USER}/Documents/data/geodata/brazilian_states_2010.gpkg"
STATES_FEATURE="brazilian_states_2010"
shopt -s nullglob
FOREST_FILES=(~/Documents/data/prodes/amazonia_legal/forest*.shp)
shopt -u nullglob 

# Path to GRASS GIS database.
GRASS_DATA="/home/${USER}/Documents/grassdata"
GRASS_DB=brstates
GRASS_MS="${GRASS_DATA}/${GRASS_DB}/PERMANENT"

# Output directory.
OUT_DIR="${HOME}/Documents/github/treesburnareasdata/data-raw"



#---- Validation ----

if command -v grass %%&> /dev/null; then
        logit "INFO: grass gis found!"
    else
        logit "ERROR: grass gis could not be found. Please install it."
        exit 1
fi

if command -v ogr2ogr &> /dev/null; then
        logit "INFO: ogr2ogr found!"
    else
        logit "ERROR: ogr2ogr could not be found. Please install it."
        exit 1
fi

is_file_valid "$STATES_GPKG"
is_dir_valid "$OUT_DIR"



#---- Import data to GRASS GIS ----

logit "INFO: Create a GRASS GIS location using DETER properties..."
(
grass -e -c "${FOREST_FILES[0]}" ${GRASS_DATA}/${GRASS_DB}
) 2>&1 | tee -a ${LOGFILE}

# NOTE: How much is 1 meter on Earth's surface in degrees at the equator?
# Using the small sine approximation: sin(x) = x
# Where sin(x) in a right triangle is the opposite side (1 meter) over the 
# hypotenuse (Earth radius: 6378137 meters, that is  WGS84's semi-major axis). 
# The answer is in radians, which we need to convert to degrees: 
# deg = rad * 180 / PI
#
# For 1 meter: 
# (1/6378137) * (180/pi) = 8.983153e-06
#
# For 10 meters: 
# (10/6378137) * (180/pi) = 8.983153e-05
#
# ANSWER: 
# One meter in degrees is   0.000008
# Ten meters in degrees are 0.00008

logit "INFO: Importing forest masks into GRASS GIS..."
for f in "${FOREST_FILES[@]}"
do 
    logit "INFO: Importing ${f}..."
    (
    fname=$(basename "${f%.*}")
    grass ${GRASS_MS} --exec v.in.ogr \
        input=${f} \
        layer=${fname} \
        output=${fname} \
        snap=0.00008
    ) 2>&1 | tee -a ${LOGFILE}
done

logit "INFO: Cleaning forest mask polygons..."
for v in "${FOREST_FILES[@]}"
do 
    vname=$(basename "${v%.*}")
    logit "INFO: Cleaning ${vname}..."
    (
    grass ${GRASS_MS} --exec v.clean -c \
        input=${vname} \
        output=${vname}_clean \
        error=${vname}_clean_errors \
        tool=snap,rmdangle,rmbridge,bpol,prune,rmdac,rmarea \
        threshold=0.000008,-1,0,0.000008,0.000008,0,25
    ) 2>&1 | tee -a ${LOGFILE}
done

# View topological errors
#d.mon start=wx0
#d.vect map=forest_2016 color=26:26:26 fill_color=77:77:77 width=5
#.vect map=forest_2016_clean_errors color=255:33:36 fill_color=none width=5 \
#    icon=basic/point size=30

logit "INFO: Dissolving forest masks..."
for v in "${FOREST_FILES[@]}"
do
    vname=$(basename "${v%.*}_clean")
    logit "INFO: Dissolving ${vname}..."
    (
    grass ${GRASS_MS} --exec v.dissolve \
        input=${vname} \
        layer=1 \
        column=main_class \
        output=${vname}_dissolve
    ) 2>&1 | tee -a ${LOGFILE}
done

logit "INFO: Importing Brazilian states into GRASS GIS..."
(
grass ${GRASS_MS} --exec v.in.ogr \
    input=${STATES_GPKG} \
    layer=${STATES_FEATURE} \
    output=${STATES_FEATURE} \
    snap=0.00008
) 2>&1 | tee -a ${LOGFILE}

logit "INFO: Cleaning Brazilian states..."
(
grass ${GRASS_MS} --exec v.clean -c \
    input=${STATES_FEATURE} \
    output=${STATES_FEATURE}_clean \
    error=${STATES_FEATURE}_clean_errors \
    tool=snap,rmdangle,rmbridge,bpol,prune,rmdac,rmarea \
    threshold=0.000008,-1,0,0.000008,0.000008,0,25
) 2>&1 | tee -a ${LOGFILE}

logit "INFO: Dissolving Brazilian states..."
(
grass ${GRASS_MS} --exec v.dissolve \
    input=${STATES_FEATURE}_clean \
    layer=1 \
    column=abbrev_state\
    output=${STATES_FEATURE}_dissolve
) 2>&1 | tee -a ${LOGFILE}


logit "INFO: Overlaying forest masks and brazilian states..." 
for v in "${FOREST_FILES[@]}"
do
    vname=$(basename "${v%.*}_clean")
    logit "INFO: Overlaying ${vname}..."
    (
    grass ${GRASS_MS} --exec v.overlay \
        ainput=${vname} \
        atype=area \
        binput=${STATES_FEATURE}_clean \
        btype=area \
        operator=and \
        output=${vname}_overlay \
        snap=0.00008
    ) 2>&1 | tee -a ${LOGFILE}
done

logit "INFO: Compute overlay areas..." 
for v in ${FOREST_FILES[@]}
do 
    vname=$(basename "${v%.*}_clean_overlay")
    logit "INFO: Computing overlay area of ${vname}..."
    (
    grass ${GRASS_MS} --exec v.to.db \
        map=${vname} \
        type=centroid \
        option=area \
        columns=area_size \
        units=meters
    ) 2>&1 | tee -a ${LOGFILE}
done

logit "INFO: Computing forest area by Brazilian state..." 
for v in ${FOREST_FILES[@]}
do 
    vname=$(basename "${v%.*}_clean_overlay")
    out_file=$(basename "${v%.*}.csv")
    logit "INFO: Writing overlay area of ${vname} to ${out_file}..."
    (
    grass ${GRASS_MS} --exec db.select \
        sql="SELECT b_abbrev_state as brstate, SUM(area_size) as area_size FROM ${vname} GROUP BY b_abbrev_state" \
        output="${OUT_DIR}/${out_file}"
    ) 2>&1 | tee -a ${LOGFILE}
done

logit "Finished!"
