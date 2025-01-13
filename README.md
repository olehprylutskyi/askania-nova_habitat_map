# Habitat Map of Falz-Fein Biosphere Reserve "Askania Nova"
Mapping habitats of Falz-Fein Biosphere Reserve "Askania Nova" using Sentinel-2 satellite data, image segmentation, and supervised classification.

Follow the link to the [Google Earth Engine App](https://ee-olegpril12.projects.earthengine.app/view/askania-nova-habitats) to view the full-size maps.

## Purpose
Mapping habitats is an essential component of assessing the condition of natural ecosystems. However, accomplishing this task using traditional field methods requires extensive human efforts and financial resources. An alternative is remote habitat mapping using satellite imagery and classification algorithms. In the context of war and the temporary occupation of parts of Ukraine, remote habitat mapping often becomes the only feasible method to obtain a snapshot of ecosystem conditions. 

We developed a habitat classification scheme for the territory of the Falz-Fein Biosphere Reserve “Askania Nova” (Kherson region, Ukraine) based on the national classification system, with certain modifications and refinements that account for the land use forms and practices specific to that area. Using field survey data collected within the Reserve before the temporary occupation, combined with image segmentation methods and supervised classification of Sentinel-2 satellite data, we composed detailed habitat maps for the entire Reserve (including the natural core, buffer, and anthropogenic landscape zones). 

The results demonstrate that the prevalent habitat types include continuous croplands (both rainfed and irrigated), true forb-bunchgrass and bunchgrass steppes of the steppe zone, fallow or recently abandoned arable lands, and temporary saline wetlands in depressions of the Steppe zone (pody). Integrating direct earth observation data with derived metrics reflecting the phenology of plant communities proved highly effective for habitat mapping. Object-based and pixel-based classifications provided equally fair results, although object-based methods minimised issues of class interference caused by misclassification of individual pixels (the “salt-and-pepper problem”). The provided open-source scripts in R and Python, included as supplementary materials, ensure the reproducibility of this method in other areas. The resulting maps represent a reliable snapshot of the pre-occupation state of the Reserve’s habitats and serve as a spatially explicit foundation for their future monitoring and change detection.

## Input Data
- [Harmonized Sentinel-2 MSI: MultiSpectral Instrument, Level-2A](https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR_HARMONIZED).
- Historical vegetation plots from the [Ukrainian Grassland Database](https://doi.org/10.7809/b-e.00217).

## Requirements
- Python 3.13
- R 4.4.2
- Google Earth Engine account

## How to Reproduce?
The whole workflow consists of both prescripted and manual steps. 
- 0_clean_datapoints.R: prepares point data from vegetation plots.
- 1_shp2geojson.R: read, validate, assign numerical class property, and convert Esri Shapefiles to ready-fot-GEE geojson files.
- 2_segmentation_classification.ipynb: the core of the analysis. A Jupyter Notebook that prepares earth observation data, performs image segmentation, train Random Forest classifier, assesses classification accuracy, and classifies both segmented and raw images.
- 3_postprocessing.R: read classification outputs and makes figures.

All R-scripts can be run at once (sourced), whereas 2_segmentation_classification.ipynb must be run step-by-step, sicne it has a lot of intermediate outputs that will be exported to the user's Google Drive forder. They must be downloaded into respective folder to ensure successful execution of further code blocks/scripts. See textual comments withing the notebook for more details.

## Credits
Autors:

- Oleh Prylutskyi (@olehprylutskyi): conceptualization, development.
- Viktor Shapoval: idea, ground truth data, habitat type classification scheme.
- Anna Kuzemko: habitat type classification scheme.

License: GNU GPL-3.

Please cite this pipeline as: Prylutskyi, Shapoval, and Kuzemko (2024) Pre-occupation status of habitats in the Falz-Fein Biosphere Reserve “Askania Nova”: inventory and mapping using remote sensing and machine learning. _Biosphere Reserve "Askania Nova" Reports_, XX, XX-XX. 
