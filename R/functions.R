mk_crs <- function(lon = 0, lat = 0) {
  sprintf("+proj=laea +lon_0=%s +lat_0=%s", sprintf("%.04f",lon), sprintf("%.04f", lat))
}
#' @importFrom reproj reproj_extent
mkcrsextent <- function(ex, crs) {
  reproj_extent(ex, "EPSG:4326", source = crs)
}
#' @importFrom fs path_abs file_temp path dir_exists path_dir dir_create
#' @importFrom vapour gdal_raster_dsn gdal_raster_nara
#' @importFrom targets tar_config_get
raster_file <- function(dsn, crs, ext, dim) {
  file <- path_abs(file_temp(pattern = "geotartif_", tmp_dir = path(tar_config_get("store"), "user"), ext = ".tif"))
  if (!dir_exists(needir <- path_dir(file))) {
    dir_create(needir)
  }
  gdal_raster_dsn(dsn,
                  out_dsn = file,
                  target_crs = crs, target_ext = ext, target_dim = dim)[[1]]
}

cleanup_tifs <- function(x, debug = TRUE) {
  alltifs <- fs::dir_ls(path_abs(path(tar_config_get("store"), "user")), regexp = "geotartif_.*tif$")
  delete <- setdiff(alltifs, x$dsn)
  if (!debug) fs::file_delete(delete)
  if (length(delete) < 1) NULL else delete
}
