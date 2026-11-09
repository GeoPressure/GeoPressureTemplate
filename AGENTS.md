# Running this GeoPressureTemplate project (guide for AI agents)

This project reconstructs bird movements from multi-sensor geolocators (pressure, light,
acceleration) with the R package GeoPressureR. You run the analysis with the user, who is often new
to it. You prepare, run, check and explain. The user labels the data in the apps and makes the
judgement calls.

## Where the answers are

GeoPressureR changes often. Do not rely on memory, old scripts or tutorials: check every function
and argument against the installed version.

- Versions: `packageVersion("GeoPressureR")` and `packageVersion("GeoLocatoR")`.
- Arguments, defaults and behaviour: `?fn` (installed version) or
  `https://geopressure.org/GeoPressureR/reference/<fn>.md` (latest release), and the source code
  when the detail matters. Changes and deprecations: `news(package = "GeoPressureR")`.
- How to do each step: the GeoPressureManual,
  `https://geopressure.org/GeoPressureManual/<chapter>.html`. This project:
  `geopressuretemplate-intro`, `-label`, `-twilight`, `-workflow`. Labelling rules and checks:
  `labelling-tracks`. Steps: `tag-object`, `pressure-map`, `trajectory`, `light-map`,
  `trajectory-with-wind`, `pressurepath`, `geopressureviz`, `geolightviz`. Publishing:
  `geolocator-create`. Read the chapter before a step you have not yet done with this user.
- Accounts and keys: `https://geopressure.org/GeoPressureManual/resources.html#accounts-and-keys`.

## Working rules

- **The user decides** which points are flights or outliers, the map extent, `sd`, the movement
  model and which results to trust. Propose a choice with your reasons, and let them decide.
- **The user labels.** `trainset()` (tag labels), `geolightviz()` (twilights) and
  `geopressureviz()` (paths) open in the browser. Ask the user to use them and say what to look
  for. Start them in the user's R session. From a shell, use `run_bg = FALSE` in a background
  process: with the default `run_bg = TRUE`, the app stops when the calling R process ends.
- **Never edit `data/raw-tag/`. Edit a label file only with the user's agreement**, then ask them
  to review it in `trainset()`.
- **Accounts and keys are the user's.** When a step needs an account (Copernicus CDS for wind,
  Zenodo to publish), say so and send the user to the accounts section above. Never ask for, type,
  print or store a key. Keys go in the system keyring, never in a script, `config.yml` or the
  repository. If you find one in a file, tell the user to revoke it.
- **Tag data are often unpublished.** Do not send them anywhere beyond what GeoPressureR itself
  sends to the GeoPressure API.
- **Some steps are slow** (pressure maps, pressure paths, wind downloads). Run them in the
  background where possible, and say what is running.
- **Look at results before saying something worked.** To see a figure yourself, use the static
  version (`plot_plotly = FALSE`, `plot_leaflet = FALSE`) and write it to a PNG file.
- **Ask before installing or updating R packages.**

## Project layout

- `config.yml`: every parameter, as `<tag id>: <function>: <argument>: value`. The `default` block
  applies to all tags, and a tag block overrides it. Change parameters here, not in the scripts.
  `geopressuretemplate_config(id)` shows the values a tag will use, and
  `GeoLocatoR::config_to_tibble()` compares the tags.
- `data/raw-tag/<id>/`: the logger files. The folder name is the tag id used everywhere else.
- `data/tag-label/`: `<id>.csv` is the initial export. `<id>-labeled.csv` is written by the
  Trainset Save button and read by `tag_label()`. `<id>-labeled-backup.csv` is Trainset's automatic
  draft; GeoPressureR does not read it. GeoLightViz saves to `data/twilight-label/<id>-labeled.csv`.
- `data/interim/<id>.RData`: the workflow results, read with `load_interim(id)`. `data/interim/`,
  `data/wind/` and `data/datapackage/` are git-ignored by default.
- `analysis/`: `1-label.qmd` and `2-twilight.qmd` (labelling, one tag at a time, nothing saved),
  `3-label-advanced.qmd` (both, compact), `10-geopressuretemplate.R` (the model) and
  `20-datapackage.R` (sharing). Adapt them, but keep one script that runs for every tag.
- `GeoLocatoR::status_geopressuretemplate()` lists the tags found in `config.yml`, `data/raw-tag/`
  and `data/interim/`, and what each interim file holds. Run it at the start of a session.

## config.yml traps

Most config mistakes raise no error. After each edit, run `geopressuretemplate_config(id)` and
check the values.

- Values are YAML, not R: a vector is `[a, b]`. Keep `!expr` for functions such as
  `log_linear_pooling_weight`.
- Each argument must sit under its function name. A key at the wrong level, such as `crop_start`
  directly under the tag id, is ignored.
- A tag id missing from `config.yml` runs with `default` alone: no crop, no known site, the
  default extent.
- Write `known` column-wise: `stap_id: [1, -1]`, then `known_lon` and `known_lat` (one value, or
  one per row). A YAML list of `- stap_id: ...` items keeps only the first site, with a warning.
- Dates are UTC, and `crop_end` is exclusive. A malformed date can be truncated without error
  (`"2018-07-015"` is read as 1 July 2018).
- The default `extent` and the tags `18LX` and `CB619` are the template's examples: replace them.
- A tag without light, or without twilight labels yet, needs `geopressuretemplate: likelihood:
  ["map_pressure"]`. Otherwise the workflow stops at the light step.
- `graph_set_movement: type: "as"` needs the tag's wind files. Use `"gs"` until they exist.
- If a function warns that an argument is deprecated, remove it from `config.yml` (see NEWS).

## Running the analysis with the user

Take one tag all the way through first, then loop over the others
(`GeoLocatoR::config_to_tibble()$id`).

### 1. Set up

- In a new project, help the user personalise `README.md`, `DESCRIPTION` (title, authors,
  licence) and the `.Rproj` name, and remove the example tags. If `git remote -v` shows
  `GeoPressure/GeoPressureTemplate`, the project was cloned from the template: help the user point
  it to their own repository.
- Ask only what the data cannot tell: species, equipment and retrieval dates and sites, whether
  the bird was recaptured where it was equipped, the area it may have reached, and anything
  unusual about the logger (clock not on UTC, early failure).

### 2. Add the tag to config.yml

- `tag_create`: `crop_start` and `crop_end` from the equipment and retrieval dates. Check on
  `plot(tag, type = "pressure")` (and acceleration, light) that they remove the time before
  attachment and after retrieval or logger failure. Clock corrections (`time_shift`, `time_drift`,
  see `?tag_create`) also go here, and must be settled before labelling.
- `tag_set_map`: an `extent` large enough for every place the bird could have been; one that is
  too small gives a wrong trajectory without any error. A coarse `scale` while labelling (see
  `?tag_set_map` for the finest useful value). `known`: the equipment site at `stap_id` 1, and at
  -1 only if the bird was recaptured there and the data run until then.
- `bird_create: scientific_name`: the exact AVONET name, used only by the wind model.

### 3. Label: the main loop

Labels define the stationary periods (`stap`) and the pressure used to locate them. Most problems
in the results come from here. Read `labelling-tracks` first; worked cases (not in the book) are in
`https://raw.githubusercontent.com/GeoPressure/GeoPressureManual/main/label-tips.qmd`.

- Show the sensors and explain them. With acceleration, `flight` goes on acceleration (`flight` on
  pressure is then ignored, with a warning), and `discard` and `elev_*` go on pressure. Without
  acceleration, everything goes on pressure.
- First round: `trainset(tag)` on an unlabelled tag starts from automatic flight labels based on
  acceleration (`tag_label_auto()`; tune its arguments if they are poor).
- **Trainset Save overwrites `<id>-labeled.csv` without asking.** To continue existing labels, open
  `trainset(id)`, never an unlabelled tag. After changing crop or clock settings, open
  `trainset(tag_label(tag))` on the re-created tag, so that the app shows the new timestamps.
  Suggest committing the label file after each round.
- After each round, rebuild the tag from `tag_create()` (a tag that went through `tag_set_map()`
  cannot be relabelled), then run `tag_label()`, `tag_set_map()` and `geopressure_map()` with a
  coarse `scale` and a lower `max_sample`. Create the tag from the resolved config, as the workflow
  does: `do.call(tag_create, c(list(id = id), geopressuretemplate_config(id)$tag_create))`. The
  analysis scripts pass only the crop dates, so with clock corrections they label other timestamps.
- Summarise for the user: the number and durations of stationary periods and flights
  (`stap2duration()`, `stap2flight()`), the warnings of `tag_label()` (unknown labels, missing
  timesteps), short periods and flights, periods whose `tag$map_pressure` layer is all zero, and
  jumps in `tag2path(tag, interp = 1)`. Give the dates to recheck.
- Checks (see `labelling-tracks`): the Check button in Trainset (short periods, short flights,
  hourly pressure jumps), then `geopressureviz(tag)`. Repeat until the user can draw a coherent
  trajectory: each position reachable in the flight time, and the tag pressure matching ERA5 at
  each position ("Query pressure"). "Export CSV" downloads `<id>-path-geopressureviz.csv` through
  the browser; read it back with `read_stap()`.

What problems look like, and their usual causes:

- A period whose pressure fits no location (an all-zero map, or `graph_create()` reports an
  invalid map): an altitude change inside the period left in, two elevations mixed, data from
  before attachment, or an extent that is too small.
- Two levels in the pressure of one period (a roost and a feeding site, a slope): label them
  `elev_1`, `elev_2`, or discard the shorter one. Zoom in on the y-axis: small steps matter.
- `graph_create()` finds no locations reachable within `thr_gs`: usually a missed flight, a flight
  cut too short, or two periods merged. Raise `thr_gs` only if the movement is plausible.
- Many very short periods or flights: fragmented flight labels, often low activity during a flight
  (gliding at the end of the night) left unlabelled.
- Birds moving up and down all day: keep the most common level; consider a larger `sd` there.

### 4. Light (if recorded)

Follow `analysis/2-twilight.qmd`. Check on `plot(tag, type = "twilight")` that night and day are
centred; otherwise set `twilight_create: twl_offset` (a warning about twilights at midnight points
to this). The user discards outlying twilights in `geolightviz(tag)` and saves. Calibration needs a
known site with twilights, or `fitted_location_duration` (see `?geolight_map`). Check
`plot_twl_calib(tag)`, and that the light and pressure maps agree in GeoPressureViz. Do not
over-edit the calibration periods: their spread is the twilight error.

### 5. Wind (optional, improves the movement model)

Needs the user's Copernicus CDS account (see the accounts section). Download only once labels and
`extent` are final: `tag_download_wind()` writes one file per flight, named by `stap_id`, covering
that flight's time, altitudes and the map extent. After any change of labels or extent, download
again (`overwrite = TRUE`, or delete `data/wind/<id>/`); `graph_add_wind()` stops when a file no
longer matches. Downloads can take hours: run them in the background. Then set
`graph_set_movement: type: "as"` and check `bird_create`.

### 6. Final run

Set the final `scale`, `max_sample` and `sd` in `config.yml` with the user. Suggest updating
GeoPressureR first, and read NEWS for changes that alter results. Run `geopressuretemplate(id)`, or
the steps in `analysis/10-geopressuretemplate.R`.

- `geopressuretemplate_tag()` rewrites `data/interim/<id>.RData` with only `tag` and `param`.
  `geopressuretemplate_graph()` replaces the trajectory outputs and keeps other objects.
  `geopressuretemplate_pressurepath()` computes the pressure paths of `most_likely` and
  `simulation` only.
- If the graph step fails, it returns the graph and saves nothing: debug with
  `graph <- geopressuretemplate_graph(id)`. Otherwise the graph is not saved (too large).
  The parameters and the GeoPressureR version used are stored in `param`.

### 7. Check the results with the user before interpreting them

- Pressure fit along the most likely path: `plot_pressurepath(pressurepath_most_likely)` (outliers
  flagged) and `type = "histogram"` (one mode per long period; periods with an empirical SD above
  `sd` are highlighted). This is also how `sd` is calibrated.
- The marginal map with the path (`plot(marginal, path = path_most_likely)`), the simulations
  (`plot_path(path_simulation)`), and flight speeds in `edge_most_likely` and `edge_simulation`
  (ground speed `abs(gs)`; airspeed `abs(gs - ws)` with wind). A last look in `geopressureviz(id)`.
- Odd results usually come from labels: go back to step 3 rather than tuning parameters. Parameter
  changes are the user's decision; record them in `config.yml`.

### 8. Share

`analysis/20-datapackage.R` builds and validates a GeoLocator Data Package (Manual chapter
`geolocator-create`). Publishing on Zenodo needs the user's account: they upload and submit. For a
methods section, take the settings from `config.yml` and `param`, and cite each package with
`citation()`.
