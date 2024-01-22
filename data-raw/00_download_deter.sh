#!/bin/bash
###############################################################################
# Download DETER data from terrabrailis.
###############################################################################

OUT_DIR="${HOME}/data/terrabrasilis/amazonia_legal"
OUT_FILE="${OUT_DIR}/deter-amz-deter-public.shp"

[ -d "${OUT_DIR}" ] || { echo "ERROR: Directory ${OUT_DIR} does not exist!" >&2; exit 1; }

if [ -f "${OUT_FILE}" ]; then
    echo "ERROR: $OUT_FILE already exists." >& 2
    exit 1
fi

wget --content-disposition -nc -t 5 http://terrabrasilis.dpi.inpe.br/file-delivery/download/deter-amz/shape -P "${OUT_DIR}" 

find "${OUT_DIR}" -type f -iname "*.zip" -exec unzip -o {} -d "${OUT_DIR}" \;

find "${OUT_DIR}" -type f -iname "*.zip" -exec rm {} \;

exit 0
