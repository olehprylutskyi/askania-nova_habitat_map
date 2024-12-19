# Set the Environment ####
rm(list = ls()) # Reser R's brain

# Set working directory
setwd("~/git/askania-nova_habitat_map")

library(tidyverse)     # data manipulation
library(sf)            # spatial vector data
library(terra)         # spatial raster data

# Part 1. Convert annotated SNIC segments ####
# Read vector data as an ESRI Shapefile
snic_ann <- sf::st_read(
  # # Default segments
  # "./snic_segments_annotated/snic_segments_annotated.shp"
  # Finer segments
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

# # Recode habitats to integer and save as geojson
# snic_ann <- snic_ann %>%
#   # Add numeric class names
#   left_join(habitat_dictionary) %>% 
#   # Write to a geojson file
#   st_write(
#     # # Default segments
#     # "./snic_segments_annotated/snic_segments_annotated.geojson"
#     # Finer segments
#     "./snic_segments_finer/snic_segments_annotated.geojson"
#   )

# Part 2. Process classification results ####
# Load classfied segments ####
snic_cl <- sf::st_read(
  "./snic_segments_classified/ExportClassifiedSegments.shp"
) %>% 
  # Fix geometry issues
  st_make_valid() %>% 
  select(label) %>% 
  rename(class_id = label) %>% 
  left_join(habitat_dictionary)


# Prepare a palette for habitat types
# Check one more time the list of classes
levels(as.factor(snic_ann$class_ch))

# Make a palette for classes used
palette_hab <- c(
  "#005d7b", #В1 
  "#4AA4C1", #В2.2.1
  "#2B8978", #В2.2.2
  "#357A9A", #В3
  "#32722e", #Д1.8
  "#954249", #С1.1.1
  "#8f262e", #С1.1.2
  "#cd202e", #С1.1.3
  "#FFE0CE", #С2.1.1а
  "#F0828B", #С2.1.1б
  "#252020", #С2.1.5
  # "#00be59", #С2.2.2 (газони)
  "#a1a1a1", #С3.1
  "#626262", #С3.2
  "#544d3c", #С3.6
  "#24080a", #С4
  "#DFC229", #Т1.4
  "#A8E787", #Т1.4а
  "#E1F54C", #Т1.4б
  "#77E686"  #Т3.2
)

# Check the palette
palette_hab

# Publication-quality Map of habitat type
ggplot() +
  geom_sf(
    data = snic_cl,
    aes(fill = class_ch),
    lwd = 0.05
  ) +
  scale_fill_manual(
    values = palette_hab
  ) +
  labs(
    # title = "Біотопи БЗ Асканія-Нова",
    fill = "Тип біотопу"
  ) +
  theme_light()

# Save the map
ggsave(
  "./outputs/habitat_map.png",
  width = 26, height = 18, units = "cm", dpi = 300
)

# Part 3. Accuracy assesment ####
# Read accuracy data fromm csv files and combine a single output
test_accur <- read_csv("./accuracy/test_overall_accuracy.csv")
test_kappa <- read_csv("./accuracy/test_kappa.csv")

# Confusion matrix
confusion_matrix <- "./accuracy/test_confusion_matrix.csv"

percentage.df <- read_csv(confusion_matrix) %>% 
  select(-1) %>% 
  `colnames<-`(habitat_dictionary$class_ch) %>% 
  # select(-ncol(.)) %>% 
  mutate(Prediction = habitat_dictionary$class_ch) %>%
  mutate(across(-Prediction, ~ (. / sum(.) * 100))) %>% # Normalise to percentages row-wise
  pivot_longer(
    cols = -Prediction, 
    names_to = "Truth", 
    values_to = "Percentage"
  ) # Convert to long format

read_csv(confusion_matrix) %>% 
  select(-1) %>% 
  `colnames<-`(habitat_dictionary$class_ch) %>% 
  # select(-ncol(.)) %>% 
  mutate(Prediction = habitat_dictionary$class_ch) %>%
  pivot_longer(
    cols = -Prediction, 
    names_to = "Truth", 
    values_to = "NumPoints"
  ) %>% # Convert to long format
  left_join(percentage.df) %>% 
  ggplot(aes(
    x = Truth, 
    y = Prediction, 
    fill = Percentage
  )) +
  geom_tile(colour = "darkgrey") +
  geom_text(
    aes(label = ifelse(NumPoints >= 1, NumPoints, "")), 
    colour = "black"
  ) +  # Plot text labels, but exclude 0s
  scale_fill_gradient(
    low = "white", 
    high = "#1B9E77"
  ) +
  labs(
    x = "Реальні значення", 
    y = "Передбачення моделі", 
    fill = "Частка (%)" # Update axis and legend labels
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1), # Rotate x-axis labels for readability
    text = element_text(size = 12) # Adjust text size for better readability
  ) -> conf_matrix_p


conf_matrix_p

png(
  "./outputs/test_confusion matrix.png",
  width = 24, height = 16, units = "cm", res = 300
)
conf_matrix_p
dev.off()

# Part 4. Calculate areas of habitat types ####

# Area of habitats by pixel-based classification
classified_r <- terra::rast(
  "./rasters/classified_pixels.tif"
)

# Check the unique values in the raster
unique(classified_r)

# Raster contains values 0-19. So, we add another color to the palette before
# the main ones.
palette_raster <- c("#ffffff", palette_hab)

# Plot raster prediction
plot(classified_r, col = palette_raster)

# Calculate area of each pixel in the raster
r_areas <- terra::cellSize(
  classified_r,
  unit = "ha"
)

r_areas

plot(r_areas)

# Combine classification raster with area raster
classified_area <- terra::mask(r_areas, classified_r)

# Calculate total area for each class
class_area <- terra::zonal(
  classified_area, 
  classified_r, 
  fun = "sum", 
  na.rm = TRUE
)

# Convert to a data frame and rename columns for clarity
class_area_df <- as.data.frame(class_area) %>% 
  filter(classification != 0) %>% 
  `colnames<-`( c("class", "total_area_ha"))

# View results
print(class_area_df)


# Area of habitats by classified segments

# Ensure your object has the correct CRS with units in metres
class_areas <- st_transform(snic_cl, crs = 32636) %>% # UTM zone 36N
    # Calculate the area of each polygon
    mutate(area_ha = as.numeric(st_area(.))/10000) %>%
    # Group by the class name variable and calculate the total area for each class
    group_by(class_ch) %>%
    summarise(total_area_ha = sum(area_ha, na.rm = TRUE)) %>%
    ungroup() %>% 
    st_drop_geometry()

# View the results
print(class_areas)

# Create a named palette to match class_ch labels
names(palette_hab) <- sort(unique(class_areas$class_ch))  # Alphabetical order of class_ch

# Reorder "class_ch" by ascending area
class_areas_desc <- class_areas %>%
  arrange(total_area_ha) %>%
  mutate(class_ch = factor(class_ch, levels = class_ch))

# Extract palette in the correct order (matching reordered class_ch)
ordered_palette <- palette_hab[levels(class_areas_desc$class_ch)]

# Create the barplot
ggplot(class_areas_desc, aes(
  x = class_ch, 
  y = total_area_ha, 
  fill = class_ch
)) +
  geom_bar(stat = "identity") +
  coord_flip() + 
  scale_fill_manual(values = ordered_palette) + 
  labs(
    x = "Тип біотопу",
    y = "Площа (га)",
    title = "Загальна площа біотопів за типами"
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    # axis.text.x = element_text(angle = 45, hjust = 1)  # Adjust text if needed
  )

ggsave(
  "./outputs/area_snic_desc.png",
  width = 16, height = 12, units = "cm", dpi = 300
)


# Combined plot of pixel-based and object-based classification areas
class_areas %>% 
  bind_cols(class_area_df) %>% 
  select(-class) %>% 
  rename(
    "Vector-Based" = "total_area_ha...2",
    "Raster-Based" = "total_area_ha...4"
  ) %>% 
  pivot_longer(
    cols = c(`Vector-Based`, `Raster-Based`),
    names_to = "area_type",
    values_to = "area_ha"
  ) %>%
  ggplot(aes(
    x = class_ch, 
    y = area_ha, 
    fill = area_type
  )) +
  geom_bar(
    stat = "identity", 
    position = position_dodge(width = 0.8)
  ) +
  labs(
    x = "Тип біотопу",
    y = "Площа (га)",
    fill = "Класифікація",
    title = "Оцінка площ біотопів за типами класифікації"
  ) +
  scale_fill_discrete(labels = c(
    "Піксельна", "Обʼєктна"
  )) +
  coord_flip() +
  theme_bw()
  # theme(
  #   panel.grid.major = element_blank(),
  #   panel.grid.minor = element_blank(),
  #   # axis.text.x = element_text(angle = 45, hjust = 1)  # Adjust text if necessary
  # )

ggsave(
  "./outputs/area_comparison.png",
  width = 16, height = 12, units = "cm", dpi = 300
)

# Export areas as csv
class_areas %>% 
  bind_cols(class_area_df) %>% 
  select(-class) %>% 
  rename(
    "object_based" = "total_area_ha...2",
    "pixel_based" = "total_area_ha...4"
  ) %>% 
  mutate(across(c(object_based, pixel_based), ~ round(.x, 2))) %>% 
  write_csv("./outputs/areas.csv")


# End of the script ####
