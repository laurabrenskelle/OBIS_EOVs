library(gh)
library(readr)
library(robis)
library(dplyr)
library(h3)
library(sf)
library(obisindicators)
library(ggplot2)

h3_indicators <- function(occ, resolution = 9) {
  
  occ <- occ %>%
    group_by(decimalLongitude, decimalLatitude, species, date_year) %>%  # remove duplicate rows
    filter(!is.na(species))  %>%
    summarize(records = n(), .groups = "drop") %>%
    collect()
  
  # return h3 cell index for occurrences in polygon
  occ_h3 <- occ %>%
    mutate(cell = h3::geo_to_h3(data.frame(decimalLatitude, decimalLongitude), res = resolution))
  
  # group by cell index and compute indicators
  idx <- obisindicators::calc_indicators(occ_h3)
  
  # convert hexagon ids to spatial features
  # NOTE: DATELINEOFFSET is inv proportional to hex_res b/c we need to look
  #       further from the dateline as hex sizes get bigger.
  dl_offset <- 60  # 60 is enough for hex_res >= 1. res 0 is weird; don't use it.
  hex_sf <- purrr::map_df(idx$cell, h3::h3_to_geo_boundary_sf) %>%
    sf::st_wrap_dateline(c(
      "WRAPDATELINE=YES",
      glue::glue("DATELINEOFFSET={dl_offset}")
    )) %>%
    dplyr::mutate(hexid = idx$cell)
  
  # merge geometry into indicator table
  grid <- hex_sf %>%
    inner_join(idx, by = c("hexid" = "cell"))
  
  return(grid)
}

# first we will pull the files where the EOV taxonomy are stored from GitHub
IDlist <- read.csv("https://raw.githubusercontent.com/ioos/marine_life_data_network/main/eov_taxonomy/IdentifierList.csv")

# you can do it this way to ensure you have the most up-to-date identifiers but I am tabling this method for now because I know the IdentifierList file is up-to-date
# first we will pull the files where the EOV taxonomy are stored from GitHub
# repo_files <- gh::gh("GET /repos/:owner/:repo/contents/:path",
#                     owner = "ioos",
#                     repo = "marine_life_data_network",
#                     path = "eov_taxonomy")
# for (file_info in repo_files) {
#  if (file_info$type == "file") {
#    download.file(file_info$download_url, destfile = file_info$name)
#  }
#}

# using the list of taxonIDs for each EOV, we will use robis to query for all occurrences
# this will take a bit to download all of the occurrences
# let's use sea turtles for our example
turtle_occ <- robis::occurrence(taxonid = IDlist$Identifiers[7])
# let's check how many occurrences we got from OBIS
nrow(turtle_occ)

grid <- h3_indicators(turtle_occ, res=1)
obisindicators::gmap_indicator(grid, "n", label = "# of records", trans = "log10", crs=4326)

ptm <- proc.time()

for (resolution in 1:5) {
  grid_dec <- h3_indicators(turtle_occ, resolution = resolution)
  geojson_string <- geojsonsf::sf_geojson(grid_dec)
  fname <- sprintf("data/seaturtle_res%s.geojson",RES)
  write(x=geojson_string, file=fname)
  proc.time() - ptm
}
