## Load your packages, e.g. library(targets).
source("./packages.R")

tar_source()

## example code internal to locations():
# rbind(data.frame(location = "Davis", lon = c(77 + 58/60 + 3/3600), lat = -(68 + 34/60 + 36/3600)),
#       data.frame(location = "Casey",
#                  lon = cbind(110 + 31/60 + 36/3600), lat =  -(66 + 16/60 + 57/3600)),
#       data.frame(location = "Heard", lon = 73.38681, lat = -53.024348),
#       data.frame(location = "Mawson", lon = 62 + 52/60 + 27/3600, lat = -(67 + 36/60 + 12/3600)),
#       data.frame(location = "Macquarie", lon = 158.93835, lat = -54.49871),
#       data.frame(location = "Kingston", lon = 147.2901, lat = -42.98682))

locations <-  function() {
  x <- c("Hobart", "Lisbon", "Auckland", "Reine", "Brisbane", "Vancouver", "Bremerhaven", "Hiroshima", "Kotor")
  tidygeocoder::geo(x) |> dplyr::transmute(location = address, lon = long, lat = lat)
}






## tar_plan supports drake-style targets and also tar_target()
tar_assign(
  {
  loc <- locations() |> tar_target()
  src <- sds::wms_arcgis_mapserver_ESRI.WorldImagery_tms() |> tar_target()
  crs <- mk_crs(loc$lon, loc$lat) |> tar_target(pattern = map(loc))
  ext <- identity(c(-1, 1, -1, 1) * 3000) |> tar_target()  ## this might become location specific
  llext <- mkcrsextent(ext, crs) |> tar_target(pattern = map(crs), iteration = "list")
  llxmin <- llext[1L] |> tar_target(pattern = map(llext))
  llxmax <- llext[2L] |> tar_target(pattern = map(llext))
  llymin <- llext[3L] |> tar_target(pattern = map(llext))
  llymax <- llext[4L] |> tar_target(pattern = map(llext))

  imfile <- raster_file(src, crs, ext, c(1024, 0)) |>
  tar_file(pattern = map(crs))
  result <- tibble(location = loc$location, dsn = imfile,
                           llxmin = llxmin, llxmax = llxmax, llymin = llymin, llymax = llymax,
                           xmin = ext[1L], xmax = ext[2L], ymin = ext[3L], ymax = ext[4L],
                           crs = crs,
                           source = tibble(source = src)) |>
                        tar_target(pattern = map(loc, crs, llxmin, llxmax, llymin, llymax, imfile))
}
)

