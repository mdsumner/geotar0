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
  file <- path_abs(file_temp(tmp_dir = path(tar_config_get("store"), "tif_files"), ext = ".tif"))
  if (!dir_exists(needir <- path_dir(file))) {
    dir_create(needir)
  }
  gdal_raster_dsn(dsn,
                  out_dsn = file,
                  target_crs = crs, target_ext = ext, target_dim = dim)[[1]]
}
#' Plot images from target 'result'
#'
#' A faceted frame is set up and each image is plotted.
#' @param nmax maximum number of images to plot in one frame (default: 24)
#' @importFrom targets tar_read_raw
#' @importFrom purrr walk map
#' @importFrom graphics par
#' @importFrom grDevices n2mfrow
#' @export
plot_ims <- function(nmax = 24) {
  if (!requireNamespace("ximage")) {
    stop("{ximage} is required for plot_ims(), install with 'remotes::install_github(\"hypertidy/ximage\")'")
  }
  x <- try(tar_read_raw("result"), silent = TRUE)
  if (inherits(x, "try-error")) stop("no 'result' found, trying runing 'targets::tar_make()'")
  nr <- nrow(x)
  n <- min(nmax, nr)
  if (n < nr) {
    message(sprintf("plotting maximum of %i ims, from %%i", n, nr))
  }
  op <- par(mar = rep(0.4, 4), mfrow = n2mfrow(n), col.main = "hotpink", cex.main= 1.2)
  #x <- lapply(x, \(.x) if(is.numeric(.x[[1]])) .x else gdal_raster_nara(.x[[1]]))
  x <- x[seq_len(n), ]
  xx <- map(x$dsn, gdal_raster_nara)
  yy <- x$location
  purrr::walk2(xx, yy, \(.x, .y) {ximage::ximage(.x, asp = 1, axes = FALSE); graphics::title(.y, line = -6)})
  par(op)
  print(sprintf("plotted images from locations %s", paste0(x$location, collapse = ", ")))
  invisible(x)
}
