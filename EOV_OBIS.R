library(gh)
library(readr)
library(robis)
library(dplyr)
library(htmlwidgets)

# let's try mangroves as our first example
# first we will pull the files where the EOV taxonomy are stored in the Marine Life Data Network GitHub
mangroves <- read.csv("https://raw.githubusercontent.com/ioos/marine_life_data_network/main/eov_taxonomy/mangroves.csv")

# doing some cleanup to get a list of aphiaIDs for our robis query
mangroves$ID <- gsub("urn:lsid:marinespecies.org:taxname.", "", mangroves$acceptedTaxonId)
mangroves$ID <- as.numeric(mangroves$ID)
mangroveIdentifiers <- paste(mangroves$ID, collapse = ", ")

# using the taxonIDs from the last step, let's search for occurrence data for mangroves
# this step may take a while
mangrove_occ <- robis::occurrence(taxonid = mangroveIdentifiers)
# let's check how many occurrences we got from OBIS
nrow(mangrove_occ)

# use the built in leaflet capability from robis to map the occurrences
m <- map_leaflet(mangrove_occ,
            provider_tiles = "Esri.WorldGrayCanvas",
            popup = function(x) { x["scientificName"] },
            )
m

# to save the leaflet map outside R
saveWidget(m, "mangroveMap.html", selfcontained = TRUE)
