# Set the Environment ####
rm(list = ls()) # Reser R's brain

# Set working directory
setwd("~/git/askania-nova_habitat_map")

library(tidyverse)     # data manipulation
library(sf)            # spatial vector data

# set custom ggplot2 theme
mytheme <- theme_bw() +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())

# Read vector data from files
# Outer border
borders <- sf::st_read(
  "./area_of_interest/bzan_borders.geojson"
)

# Read point data (vegetation plots)
plots <- read_csv(
  "./vegetation_plots/askania_habitats_eunis_241121.csv"
) %>% 
  select(
ID, date, latitude, longitude, eunis
) %>% 
  mutate(
date = as.Date(as.character(date), format = "%Y%m%d")
)


# Explore the data
ggplot(
  data = plots, 
  aes(x = date)
) +
  geom_histogram() +
  mytheme

# Define range of years
start_year <- 2000
end_year <- 2020

# Processing steps
recent_plots <- plots %>%
  # Filter by date range
  filter(date >= as.Date(paste0(start_year, "-01-01")) & 
         date <= as.Date(paste0(end_year, "-12-31"))) %>%
  # Group by unique spatial locations (latitude and longitude)
  group_by(latitude, longitude) %>%
  # Keep only the most recent date within each group
  slice_max(order_by = date, n = 1) %>%
  ungroup() %>% 
  # convert to `simple features` spatial object
  st_as_sf(
    dim = "XY", remove = FALSE, na.fail = F,
    coords = c("longitude", "latitude"),
    crs = "+proj=longlat +datum=WGS84 +no_defs"
  )


ggplot(
  data = recent_plots, 
  aes(x = date, fill = eunis)
) +
  geom_histogram() +
  labs(caption = paste0(
    "Total plots = ",
    nrow(recent_plots)
  )) +
  mytheme


# Preview maps
ggplot() +
  geom_sf(data = borders) +
  # geom_sf(data = parcels) +
  geom_sf(
    data = recent_plots,
    aes(color = eunis)
  ) +
  mytheme

# Write cleaned datapoints to a local CSV file
# Convert to dataframe and save as CSV
recent_plots %>% 
  # # Add coordinate columns
  # mutate(
  #   lon = sf::st_coordinates(.)[,1],
  #   lat = sf::st_coordinates(.)[,2]
  # ) %>% 
  # Drop geometry (convert to data frame)
  st_drop_geometry() %>% 
  # Write points to the CSV file
  write.csv(
    file = "./vegetation_plots/vegplots_filtered.csv",
    row.names = FALSE
  )

# End of the script
