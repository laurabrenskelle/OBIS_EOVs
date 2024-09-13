library(gh)
library(readr)
library(robis)
library(dplyr)

# first we will pull the files where the EOV taxonomy are stored from GitHub
repo_files <- gh("GET /repos/:owner/:repo/contents/:path",
                 owner = "ioos",
                 repo = "marine_life_data_network",
                 path = "eov_taxonomy")

for (file_info in repo_files) {
  if (file_info$type == "file") {
    download.file(file_info$download_url, destfile = file_info$name)
  }
}

# let's try mangroves as our first example
mangroves <- read.csv("mangroves.csv")
mangroves$ID <- gsub("urn:lsid:marinespecies.org:taxname.", "", mangroves$acceptedTaxonId)
mangroves$ID <- as.numeric(mangroves$ID)
mangroveIdentifiers <- paste(mangroves$ID, collapse = ", ")
print(mangroveIdentifiers)

# using the taxonIDs, let's search for occurrence data for this EOV
mangrove_occ <- robis::occurrence(taxonid = mangroveIdentifiers)
# let's check how many occurrences we got from OBIS
nrow(mangrove_occ)

# use the built in leaflet capability from robis to map the occurrences
map_leaflet(mangrove_occ,
            provider_tiles = "Esri.WorldGrayCanvas",
            popup = function(x) { x["scientificName"] },
            )