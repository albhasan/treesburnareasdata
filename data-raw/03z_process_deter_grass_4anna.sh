#!/bin/bash
###############################################################################
# PRODESS DETER DATA AND BUILD SUBAREA DATASET.
###############################################################################


#---- Setup ----

# Path to the DETER file downloaded from TERRABRASILIS
DETER_SHP="/home/alber/Documents/grass_test/data/deter/amazonia_legal/deter_public.shp"

# Path to GRASS GIS database.
GRASS_DATA="/home/alber/Documents/grass_test/grassdata"
GRASS_DB=deter
GRASS_MS="${GRASS_DATA}/${GRASS_DB}/PERMANENT"

# Path to results.
OUT_GPKG="/home/alber/Documents/grass_test/out_dir/"\
"deter_subareas_grass.gpkg"
OUT_LAYER_SUBAREAS=deter_subareas



#---- Import data to GRASS GIS ----

# Create a GRASS location using DETER properties.
grass -e -c ${DETER_SHP} ${GRASS_DATA}/${GRASS_DB}

# TODO: add an ID to the DETER polygons BEFORE intersecting them!

# Import DETER data to GRASS GIS. GRASS cleans and intersects the polygons.
grass ${GRASS_MS} --exec v.in.ogr input=${DETER_SHP} \
    output=deter_subareas_raw snap=1e-06 min_area=900
# Clean and build subareas.
grass ${GRASS_MS} --exec v.clean -c input=deter_subareas_raw \
    output=deter_subareas_clean type=boundary \
    tool=rmline,rmdangle,rmsa,break,bpol,rmdupl,rmarea,rmbridge \
    threshold=0,-1,0,0,0,0,900,0
grass ${GRASS_MS} --exec g.remove -f type=vect name=deter_subareas_raw

grass ${GRASS_MS} --exec g.rename vector=deter_subareas_clean,deter_subareas

# Add column xy_id. This is created by combining centroids' coordinates.
grass ${GRASS_MS} --exec v.to.db map=deter_subareas type=centroid option=coor \
    columns="x,y"
grass ${GRASS_MS} --exec v.db.update map=deter_subareas col=x \
    qcol="round(x, 6)"
grass ${GRASS_MS} --exec v.db.update map=deter_subareas col=y \
    qcol="round(y, 6)"
grass ${GRASS_MS} --exec v.db.addcolumn map=deter_subareas \
    columns="xy_id varchar"
grass ${GRASS_MS} --exec v.db.update map=deter_subareas col=xy_id \
    qcol="x || ';' || y"
grass ${GRASS_MS} --exec v.db.dropcolumn map=deter_subareas columns=x,y

# Add column area.
grass ${GRASS_MS} --exec v.to.db map=deter_subareas option=area type=boundary \
    columns=subarea_ha units=hectares

# TODO: There are many polygons without xy_id

grass ${GRASS_MS} --exec v.db.select deter_subareas where="xy_id is null" | wc -l


exit 0
