# Set the Environment ####
rm(list = ls()) # Reser R's brain

# Set working directory
setwd("~/git/askania-nova_habitat_map")

library(tidyverse)     # data manipulation
library(sf)            # spatial vector data


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

# Accuracy assesment
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
  theme_minimal() +
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



# End of the script ####
