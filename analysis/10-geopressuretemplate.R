# https://raphaelnussbaumer.com/GeoPressureManual/geopressuretemplate-workflow.html
library(GeoPressureR)
library(GeoLocatoR)

# Get all the tag_id
list_id <- config_to_tibble()$id


## OPTION 1: Run workflow step-by-step for a single tag
id <- "18LX" # Run a single tag
geopressuretemplate_config(id)
tag <- geopressuretemplate_tag(id)
graph <- geopressuretemplate_graph(id)
geopressuretemplate_pressurepath(id)


## OPTION 2: All tracks, step-by-step

# 1. Compute likelihood map
for (id in list_id) {
  geopressuretemplate_tag(id)
}

# 2. (optional) Manual check of labeling
# geopressureviz("18LX")

# 3. (optional) Add wind
# ecmwfr::wf_set_key("abcd1234-foo-bar-98765431-XXXXXXXXXX") <https://cds.climate.copernicus.eu/profile>
for (id in list_id) {
  load_interim(id)
  tag_download_wind(tag)
}

# 4. Run graph
for (id in list_id) {
  geopressuretemplate_graph(id)
}

# 5. Run pressurepath
for (id in list_id) {
  geopressuretemplate_pressurepath(id)
}


## OPTION 3: Run entire workflow for all tags
for (id in list_id) {
  geopressuretemplate(id)
}
