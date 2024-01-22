#!/usr/bin/env Rscript
###############################################################################
# Proces PRODES data.
# - Rasterize PRODES using PRODES' shapefiles
#------------------------------------------------------------------------------
# NOTE: We rasterize the PRODES shapefiles to get acces to the VIEW_DATE column
#       and to be sure the raster VIEW_DATE fits the PRODES raster. Our PRODES
#       raster doesn't fit exactly the TerraBrasilies raster. This could, for
#       example, change the results of computing the mode in each DETER
#       subarea.
###############################################################################

library(dplyr)
library(ensurer)
library(readr)
library(sf)
library(tidyr)
library(terra)


#---- Set up ----

out_dir <- "/home/alber/Documents/data/treesburnedareas"
stopifnot("Out directory not found: " = dir.exists(out_dir))

prodes_year <- "2021"

prodes_raster   <- file.path(out_dir, "prodes_raster.tif")
prodes_viewdate <- file.path(out_dir, "prodes_viewdate.tif")
rm(out_dir)

# NOTE: Use the biome, not the Brazilian Legal Amazon.
data_dir <- "/home/alber/data/prodes/amazonia"
stopifnot("Data directory not found: " = dir.exists(data_dir))
cloud_shp <- file.path(data_dir, "cloud_biome.shp")
def07_shp <- file.path(data_dir, "accumulated_deforestation_2007_biome.shp")
defor_shp <- file.path(data_dir, "yearly_deforestation_biome.shp")
fores_shp <- file.path(data_dir, "forest_biome_2021.shp")
hydro_shp <- file.path(data_dir, "hydrography_biome.shp")
nofor_shp <- file.path(data_dir, "no_forest_biome.shp")
resid_shp <- file.path(data_dir, "residual_biome.shp")
prodes_tif <- file.path(data_dir,
                        "PDigital2000_2021_AMZ_raster_v20220915_bioma.tif")

stopifnot("PRODES files not found!" = file.exists(cloud_shp, def07_shp,
                                                  defor_shp, fores_shp,
                                                  hydro_shp, nofor_shp,
                                                  resid_shp, prodes_tif))
stopifnot("The PRODES year doesn't match the PRODES tif" =
          all(stringr::str_detect(basename(prodes_tif),
                                  pattern = prodes_year)))
stopifnot("The PRODES year doesn't match the PRODES forest shp" =
          all(stringr::str_detect(basename(fores_shp),
                                  pattern = prodes_year)))

stopifnot("Ouput file already exists!" = !(file.exists(prodes_raster)))
stopifnot("Ouput file already exists!" = !(file.exists(prodes_viewdate)))



#---- Rasterize PRODES ----

# Get PRODES codes.
prodes_codes <-
    treesburnareas::get_prodes_codes() %>%
    tidyr::pivot_longer(cols = -tidyselect::any_of("prodes_code"),
                        names_to = c("X1", "source", "year"),
                        names_sep = "_",
                        values_to = "prodes_class") %>%
    dplyr::filter(source == "shp",
                  year == prodes_year) %>%
    dplyr::select(prodes_code, prodes_class) %>%
    ensurer::ensure_that(
        nrow(.) > 0,
        err_desc = "No PRODES codes found for the given type and year.") %>%
    (function(x) {
        x %>%
            dplyr::pull(prodes_code) %>%
            magrittr::set_names(x[["prodes_class"]]) %>%
            return()
    })

# Read PRODES' shapefiles.
cloud_sf <- sf::read_sf(cloud_shp)
def07_sf <- sf::read_sf(def07_shp)
defor_sf <- sf::read_sf(defor_shp)
fores_sf <- sf::read_sf(fores_shp)
hydro_sf <- sf::read_sf(hydro_shp)
nofor_sf <- sf::read_sf(nofor_shp)
resid_sf <- sf::read_sf(resid_shp)
rm(cloud_shp, def07_shp, defor_shp, fores_shp, hydro_shp, nofor_shp, resid_shp)

# Find the common names among PRODES' shapefiles.
common_names <- Reduce(intersect, lapply(list(cloud_sf, def07_sf, defor_sf,
                                              fores_sf, hydro_sf, nofor_sf,
                                              resid_sf),
                                         colnames))

# Bind the PRODES' shapefiles into one.
prodes_sf <- rbind(cloud_sf[cloud_sf$class_name == paste0("NUVEM_",
                                                          prodes_year),
                            common_names],
                   def07_sf[common_names],
                   defor_sf[common_names],
                   fores_sf[common_names],
                   hydro_sf[common_names],
                   nofor_sf[common_names],
                   resid_sf[common_names])
rm(cloud_sf, def07_sf, defor_sf, fores_sf, hydro_sf, nofor_sf, resid_sf,
   common_names)

# Recode class names into integers.
prodes_sf <-
    prodes_sf %>%
    dplyr::mutate(prodes_code = dplyr::recode(class_name, !!!prodes_codes,
                                              .default = NA_integer_,
                                              .missing = NA_integer_)) %>%
    dplyr::select(prodes_code, image_date)

stopifnot("Unmatched PRODES codes found!" =
          sum(is.na(prodes_sf[["prodes_code"]])) == 0)

# Rasterize PRODES.
terra::rasterize(terra::vect(prodes_sf),
                 terra::rast(prodes_tif),
                 fun = "min",
                 field = "prodes_code",
                 background = 255,
                 touches = FALSE,
                 update = FALSE,
                 sum = FALSE,
                 cover = FALSE,
                 filename = prodes_raster,
                 overwrite = FALSE,
                 wopt = list(datatype = "INT1U",
                             gdal = c("COMPRESS=LZW",
                                      "BIGTIFF=YES"),
                             NAflag = 255))


#---- Rasterize PRODES' view date ----

# NOTE: Convert PRODES' image date to number of days since 1970-01-01.
prodes_date_sf <-
    prodes_sf %>%
    dplyr::filter(!is.na(image_date),
                  image_date != " ") %>%
    dplyr::mutate(prodes_date = as.integer(as.Date(image_date)))

terra::rasterize(x = terra::vect(prodes_date_sf),
                 y = terra::rast(prodes_tif),
                 fun = "min",
                 field = "prodes_date",
                 background = -32768,
                 touches = FALSE,
                 update = FALSE,
                 sum = FALSE,
                 cover = FALSE,
                 filename = prodes_viewdate,
                 overwrite = FALSE,
                 wopt = list(datatype = "INT2S",
                             gdal = c("COMPRESS=LZW",
                                      "BIGTIFF=YES"),
                             NAflag = -32768))

