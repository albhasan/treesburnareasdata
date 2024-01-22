#!/usr/bin/Rscript
###############################################################################
# Download GABAM fire data for Brazil
#------------------------------------------------------------------------------
# Adapted from https://www.victor-vandermeers.ch/post/r-gabam/
###############################################################################

library(curl)
library(tibble)
library(dplyr)
library(purrr)



#---- Setup ----

out_dir <- "/home/alber/data/gabam/"

years <- 1985:2024

cells <- c("N00W080", "N00W070", "N00W060", "N00W050", "N00W040",
           "S10W080", "S10W070", "S10W060", "S10W050", "S10W040",
           "S20W080", "S20W070", "S20W060", "S20W050", "S20W040",
           "S30W080", "S30W070", "S30W060", "S30W050", "S30W040",
           "S40W080", "S40W070", "S40W060", "S40W050", "S40W040")

time_out <- 3600 * 3



#---- Utilitary funcitons ----

#' Download GABAM fire data from FTP server 1
#'
#' @param years The years to download.
#' @param cell  The cells to download.
#' @param dest  The output directory.
gabam_download <- function(year, cell, out_dir){
    for(y in year){
        for(c in cell){
            url <- paste0("ftp://124.16.184.141/GABAM/burned%20area/",
                          as.character(y),"/",c,".TIF")
            file_path <- file.path(out_dir, y, basename(url))

            if (!dir.exists(dirname(file_path)))
                dir.create(dirname(file_path))

            if (file.exists(file_path) && file.size(file_path) == 0)
                file.remove(file_path)

            if (!file.exists(file_path)) {
                h <- curl::new_handle(url = url)
                curl::multi_add(h, data = file_path)
            }
        }
    }
    curl::multi_run(timeout = time_out)
}

#' Count the number of files in the given directory.
#'
#' @param path A character.
#' @return     A numeric.
count_files <- function(path) {
    path %>%
        list.files(recursive = TRUE) %>%
    length() %>%
    return()
}



#---- Download data ----

gabam_download(years, cells, out_dir)



#---- Cleaning ----

# Remove 0-size files.
out_dir %>%
    list.files(pattern = "*.(TIF|tif)",
               recursive = TRUE,
               full.names = TRUE) %>%
    tibble::as_tibble() %>%
    dplyr::rename(file_path = value) %>%
    dplyr::mutate(file_size = file.size(file_path)) %>%
    dplyr::filter(file_size == 0) %>%
    dplyr::pull(file_path) %>%
    file.remove()

# Remove empty directories.
out_dir %>%
    list.dirs() %>%
    tibble::as_tibble() %>%
    dplyr::rename("dir_path" = value) %>%
    dplyr::mutate(file_count = purrr::map_int(dir_path, count_files)) %>%
    dplyr::filter(dir_path != out_dir, file_count == 0) %>%
    dplyr::pull(dir_path) %>%
    unlink(recursive = TRUE)

