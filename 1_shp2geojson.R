# Set the Environment ####
rm(list = ls()) # Reser R's brain

# Set working directory
setwd("~/git/askania-nova_habitat_map")

library(tidyverse)     # data manipulation
library(sf)            # spatial vector data

# Part 1. Convert annotated SNIC segments ####
# Read vector data as an ESRI Shapefile
snic_ann <- sf::st_read(
  # ESRI Shapefile with manually annotated segments
  "./snic_segments_annotated/snic_segments_annotated.shp"
) %>% 
  # Fix geometry issues
  st_make_valid() %>% 
  select(class_ch)


# Prepare dictionary for recoding characted class names to numeric ones
habitat_dictionary <- tibble(
  class_ch = levels(as.factor(snic_ann$class_ch)),
  class_id = c(1:length(levels(as.factor(snic_ann$class_ch))))
)

# Recode habitats to integer and save as geojson
snic_ann <- snic_ann %>%
  # Add numeric class names
  left_join(habitat_dictionary) %>% 
  # Write to a geojson file
  st_write(
    "./snic_segments_annotated/snic_segments_annotated.geojson"
  )

# End of the script ####
