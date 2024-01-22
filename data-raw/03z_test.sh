#!/bin/bash
echo "ERROR: This script is deprecated. Use QGIS instead." >& 2
exit 1

# Path to the DETER file downloaded from TERRABRASILIS
DETER_SHP="/home/alber/Documents/github/treesburnareas/inst/extdata/test/"\
"deter_public.shp"

# Path to PRODES' vector mask.
PRODES_GPKG="/home/alber/Documents/data/prodes/prodes_mask.gpkg"
PRODES_MASK="prodes_mask"

# Path to GRASS GIS database.
GRASS_DATA="/home/alber/Documents/grassdata2"
GRASS_DB=test
GRASS_MS="${GRASS_DATA}/${GRASS_DB}/PERMANENT"

# Path to results.
OUT_GPKG="/home/alber/Documents/data/deter/amazonia_legal/"\
"deter_subareas_grass_test"
OUT_LAYER_SUBAREAS=deter_subareas
OUT_LAYER_FIRE_SPOTS=fire_spots


# Create a GRASS location using DETER properties.
grass -e -c ${DETER_SHP} ${GRASS_DATA}/${GRASS_DB}

# Import PRODES mask.
grass ${GRASS_MS} --exec v.in.ogr input=${PRODES_GPKG} layer=${PRODES_MASK} \
    output=prodes_mask_raw
grass ${GRASS_MS} --exec v.clean -c input=prodes_mask_raw output=prodes_mask \
    type=boundary tool=rmline,rmdangle,rmsa,break,bpol,rmdupl,rmarea,rmbridge \
    threshold=0,-1,0,0,0,0,900,0
grass ${GRASS_MS} --exec v.build -e map=prodes_mask error=prodes_mask_error
grass ${GRASS_MS} --exec g.remove -f type=vect name=prodes_mask_raw
# Add in_prodes column.
grass ${GRASS_MS} --exec v.db.addcolumn map=prodes_mask \
    columns="in_prodes integer"
grass ${GRASS_MS} --exec v.db.update map=prodes_mask col=in_prodes \
    query_column=DN

# Import DETER data to GRASS GIS. GRASS cleans and intersects the polygons.
# NOTE: The snap argument was taken from GRASS suggestions.
grass ${GRASS_MS} --exec v.in.ogr input=${DETER_SHP} \
    output=deter_subareas_raw snap=1e-06 min_area=900
# Add an number to group subareas coming from the same DETER warning.
grass ${GRASS_MS} --exec v.db.addcolumn map=deter_subareas_raw \
    columns="deter_warning int"
grass ${GRASS_MS} --exec v.db.update map=deter_subareas_raw col=deter_warning \
    qcol=cat
# Clean and build subareas.
grass ${GRASS_MS} --exec v.clean -c input=deter_subareas_raw \
    output=deter_subareas_clean type=boundary \
    tool=rmline,rmdangle,rmsa,break,bpol,rmdupl,rmarea,rmbridge \
    threshold=0,-1,0,0,0,0,900,0
grass ${GRASS_MS} --exec v.build -e map=deter_subareas_clean \
    error=deter_subareas_clean_error
grass ${GRASS_MS} --exec g.remove -f type=vect name=deter_subareas_raw

###############################################################################
# NOTE: Adding centroids converts the islands into polygons. I didn't find a 
#       way to identify the islands in the table.
# grass ${GRASS_MS} --exec v.centroids input=deter_subareas_clean \
#     output=deter_subareas
# NOTE: This doesn't seem to do anything.
# grass ${GRASS_MS} --exec v.category input=deter_subareas_clean \
#     output=deter_subareas option=add
# grass ${GRASS_MS} --exec g.remove -f type=vect name=deter_subareas_clean
# NOTE: There are polygons (a lot) missing xy_id because there are many 
#       elements with the same category. I guess it's related to the warning
#       below thrown when calling v.to.db to add X, Y coordinates to the table:
# update deter_subareas set  x = -65.9480739288316, y = -9.31875433627535  where cat = 1
# update deter_subareas set  x = -65.9415278313791, y = -9.32089181756539  where cat = 2
# WARNING: More elements of category 3, nothing loaded to database
grass ${GRASS_MS} --exec g.rename vector=deter_subareas_clean,deter_subareas
###############################################################################

# Add xy_id. It is created by combining centroids' coordinates.
grass ${GRASS_MS} --exec v.to.db -s map=deter_subareas type=centroid \
    layer="xy_id" option=coor columns="x,y"  --overwrite
grass ${GRASS_MS} --exec v.db.update map=deter_subareas col=x \
    qcol="round(x, 6)"
grass ${GRASS_MS} --exec v.db.update map=deter_subareas col=y \
    qcol="round(y, 6)"
grass ${GRASS_MS} --exec v.db.addcolumn map=deter_subareas \
    columns="xy_id varchar"
grass ${GRASS_MS} --exec v.db.update map=deter_subareas col=xy_id \
    qcol="x || ';' || y"
grass ${GRASS_MS} --exec v.db.dropcolumn map=deter_subareas columns=x,y
# Add area.
grass ${GRASS_MS} --exec v.to.db map=deter_subareas option=area type=boundary \
    columns=subarea_ha units=hectares
# Add in_prodes using the PRODES mask.
grass ${GRASS_MS} --exec v.type input=deter_subareas from_type=centroid \
    to_type=point output=deter_point 
grass ${GRASS_MS} --exec g.remove -f type=vect name=deter_subareas
grass ${GRASS_MS} --exec v.db.addcolumn map=deter_point column="in_prodes INT"
grass ${GRASS_MS} --exec v.what.vect map=deter_point column=in_prodes \
    query_map=prodes_mask query_column=in_prodes dmax=0.0
grass ${GRASS_MS} --exec v.type input=deter_point from_type=point \
    to_type=centroid output=deter_subareas
grass ${GRASS_MS} --exec g.remove -f type=vect name=deter_point

# Export the results.
# TODO: Check results, qgis shows some subareas without xy_id!
# NOTE: Those areas without xy_id are probably island. GRASS is exporting them
#       even without using -c. Could it be because of teh v.centroids?
grass ${GRASS_MS} --exec v.out.ogr layer="1" input=deter_subareas type=area \
    format=GPKG output="${OUT_GPKG}_1.gpkg" \
    output_layer=${OUT_LAYER_SUBAREAS} --overwrite

grass ${GRASS_MS} --exec v.out.ogr layer="2" input=deter_subareas type=area \
    format=GPKG output="${OUT_GPKG}_2.gpkg" \
    output_layer=${OUT_LAYER_SUBAREAS} --overwrite

grass ${GRASS_MS} --exec v.out.ogr layer="2" input=deter_subareas_clean_error type=area \
    format=GPKG output="${OUT_GPKG}_3.gpkg" \
    output_layer=${OUT_LAYER_SUBAREAS} --overwrite

grass ${GRASS_MS} --exec v.out.ogr layer="-1" input=deter_subareas_clean_error type=area \
    format=GPKG output="${OUT_GPKG}_4.gpkg" \
    output_layer=${OUT_LAYER_SUBAREAS} --overwrite

exit 0
