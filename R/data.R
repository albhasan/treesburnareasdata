#' @title Data Frame of the subareas of deforestation alerts from 2008 to 2021
#'
#' @description A dataset containing a tibble object with no-spatial data of
#'   subareas of DETER's deforestation alerts and PRODES's deforestation areas.
#'   DETER subareas are segments of DETER alerts which have continuity over
#'   time, that is, their shape do not change over time. Capitalized names are
#'   the DETER attributes corresponding to the warnings. The code required to
#'   download the data required and create these dataset are available in the
#'   directory data-raw. When PRODES is updated (currently PRODES 2021
#'   v20220915 is used), also updated its classes codes (see file
#'   PDigital2000_2021_AMZ_raster_v20220915_bioma.txt) in the script
#'   04_process_deter.R at the definition fo the variable prodes_classes.
#' @name subarea_tb
#' @docType data
#' @keywords datasets
#' @usage data(subarea_tb)
#' @format A tibble with 1085482 rows and 17 variables:
#'   CLASSNAME: Name of warning or deforestation,
#'   QUADRANT: Out of use. CBERS AWFI quadrant,
#'   PATH_ROW: Path and row of the used satellite images,
#'   VIEW_DATE: Date of the images used to identify a warning,
#'   SENSOR: Name of the sensor which take the images,
#'   SATELLITE: Name of the satellite which took the images,
#'   AREAUCKM: Warning area intesecting a conservation unit,
#'   UC: Name of conservation unit,
#'   AREAMUNKM: Warning area intersecting a municipality,
#'   MUNICIPALI:Name of municipality intersecting a warning,
#'   GEOCODIBGE: IBGE's code for the municipality,
#'   UF: Brazilian state name,
#'   xy_id: Subarea ID based on its centroid coordinates,
#'   subarea_ha: Subarea extent in hectares,
#'   in_prodes: Does the subarea intersect the PRODES mask,
#'   year: PRODES year,
#'   data_source: Source of the data; either DETER or PRODES,
NULL

#' @title sf object with the subareas of deforestation alerts from 2008 to 2021
#'
#' @description An sf object containing polygons corresponding to the dataset
#' subarea_tb.
#' @name subarea_sf
#' @docType data
#' @keywords datasets
#' @usage data(subarea_sf)
#' @format A tibble with 807069 rows and 2 variables:
#'   subarea_id: ID of the subarea,
#'   geom: geometry field.
NULL


#' @title sf object with fire spots from 2015 to 2022 of the Brazilian Amazon
#'
#' @description An sf object containing points corresponding to the
#' data from satellite NP-375 downloaded from INPE's queimadas platform.
#' The dataset contains data from 2015-08-01 to 2022-07-26.
#' @name fire_sf
#' @docType data
#' @keywords datasets
#' @usage data(fire_sf)
#' @format A tibble with 4428447 rows and 16 variables:
#'   datahora: Date time of observation,
#'   satelite: Name of the satellite,
#'   pais: Country name,
#'   estado: State name,
#'   municipio: Town name,
#'   bioma: Biome,
#'   diasemchuv: Number of days without rain,
#'   precipitac: TODO,
#'   riscofogo: Fire risk,
#'   latitude: Latitude,
#'   longitude: Longitude,
#'   frp: Fire Radiative Power,
#'   xy_id: Subarea id (based on their centroid coordinates),
#'   prodes_code: Land Use-Cover code in PRODES 2021,
#'   prodes_date: View date in PRODES 2021,
#'   year: PRODES year,
#'   geom: geometry field,
NULL

