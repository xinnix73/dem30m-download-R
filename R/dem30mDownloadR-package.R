#' dem30mDownloadR: Download 30 m GEDTM30 digital terrain model data
#'
#' The package downloads GEDTM30 digital terrain model data from OpenTopography for a
#' polygon boundary. It supports GeoJSON and ESRI Shapefile inputs, reads API
#' keys from a local text file, selects a suitable UTM coordinate reference
#' system, and writes a masked GeoTIFF.
#'
#' @docType package
#' @name dem30mDownloadR-package
#' @author Yihao Xin \email{xinyihao123@@foxmail.com}
#' @references
#' OpenTopography Global DEM API, providing GEDTM30 DTM data:
#' \url{https://portal.opentopography.org/apidocs/#/Public/getGlobalDem}
#' @keywords internal
"_PACKAGE"
