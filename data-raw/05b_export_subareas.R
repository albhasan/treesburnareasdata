#!/usr/bin/env Rscript
###############################################################################
# EXPORT SUBAREAS FROM R TO GEOPACKAGE
###############################################################################

library(magrittr)
library(sf)

library(treesburnareas)

out_dir <- "/home/alber/Documents/data/treesburnedareas"
out_file <- file.path(out_dir, "deter_subareas_flat.gpkg")

stopifnot("Output directory not found!" = dir.exists(out_dir))
stopifnot("Output file already exists" = !file.exists(out_file))

treesburnareas::subarea_sf %>%
    sf::write_sf(dsn = out_file, layer = "subareas_flat")

