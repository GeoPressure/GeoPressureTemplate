# https://raphaelnussbaumer.com/GeoPressureManual/geolocator-create.html

library(GeoLocatoR)

# Step 1. Create package from GeoPressureTemplate
pkg <- read_geopressuretemplate()

# Check for basic information
print(pkg)


# Step 2. Export tags/observations and complete metadata manually in CSV
# write.csv(tags(pkg), file = "data/tags.csv", row.names = FALSE)
# write.csv(observations(pkg), file = "data/observations.csv", row.names = FALSE)
# pkg <- read_geopressuretemplate()

# Validate
validate_gldp(pkg)

# Step 3. Visual checks
plot(pkg, "ring")
plot(pkg, "coverage")
plot(pkg, "map")

# Step 4. Write files locally to upload on Zenodo
write_gldp(pkg, "data/datapackage")

# Step 5. Create record on Zenodo
# https://zenodo.org/uploads/new

# Step 6. Validate Zenodo draft content before submitting
# keyring::key_set_with_value("ZENODO_TOKEN", password = "{your_zenodo_token}")
pkg <- read_zenodo(
  "{your_reserved_doi}",
  draft = TRUE, # draft record
)

validate_gldp(pkg)
