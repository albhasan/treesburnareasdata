library(dplyr)
library(geobr) 
library(sf)

sf::sf_use_s2(FALSE)

br_state <- 
    geobr::read_state(year = 2010) %>%
    sf::st_make_valid()

stopifnot("Brazilian states are invalid!" = all(sf::st_is_valid(br_state)))

sf::st_write(br_state, "~/Documents/data/geodata/brazilian_states_2010.gpkg")
