#!/bin/bash
###############################################################################
# Download auxiliary data from from terrabrailis (amazonia biome).
###############################################################################

OUT_DIR="${HOME}/data/terrabrasilis"

[ -d "${OUT_DIR}" ] || { echo "ERROR: Directory ${OUT_DIR} does not exist!" >&2; exit 1; }

FILE_COUNT="$(find ${OUT_DIR} -maxdepth 1 -type f -printf x | wc -c)"
if (( ${FILE_COUNT} > 0 )); then
    echo "ERROR: $OUT_DIR isn't empty." >& 2
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
URL_FILE="${SCRIPT_DIR}/urls_amazon_ancillary.txt"
if [ ! -f "${URL_FILE}" ]; then
    echo "ERROR: $URL_FILE not found!" >& 2
    exit 1
fi

wget -i "${SCRIPT_DIR}"/urls_amazon_ancillary.txt -P "${OUT_DIR}" -t 5

find "${OUT_DIR}" -type f -iname "*.zip" -exec unzip  {} -d "${OUT_DIR}" \;

find "${OUT_DIR}" -type f -iname "*.zip" -exec rm {} \;

exit 0

