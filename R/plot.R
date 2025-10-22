#' Plot images from target 'result'
#'
#' A faceted frame is set up and each image is plotted.
#'
#' This is for interactive use, i.e. `plot_ims(nmax = 12)` it can't run as a target.
#'
#' @param nmax maximum number of images to plot in one frame (default: 24)
#' @importFrom targets tar_read_raw
#' @importFrom purrr walk map
#' @importFrom graphics par
#' @importFrom grDevices n2mfrow
#' @export
plot_ims <- function(x = tar_read(result), nmax = 25) {
  if (!requireNamespace("ximage")) {
    stop("{ximage} is required for plot_ims(), install with 'remotes::install_github(\"hypertidy/ximage\")'")
  }
  #x <- try(tar_read_raw("result"), silent = TRUE)
  #if (inherits(x, "try-error")) stop("no 'result' found, trying runing 'targets::tar_make()'")
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
