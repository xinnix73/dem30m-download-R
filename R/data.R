#' SCBI GEDTM30 sample boundary
#'
#' A WGS84 GeoJSON polygon used as the example boundary for the package.
#' The boundary and its buffer describe the SCBI study area used in the
#' sample GEDTM30 download.
#'
#' @format A polygon feature collection stored as GeoJSON in
#'   `inst/extdata/boundary_buffer.geojson`. Horizontal CRS: WGS 84
#'   (EPSG:4326).
#' @docType data
#' @keywords datasets
#' @name scbi_boundary
#' @examples
#' boundary_path <- system.file(
#'   "extdata", "boundary_buffer.geojson",
#'   package = "dem30mDownloadR"
#' )
#' @source Original study-area boundary supplied for the GEDTM30 download.
NULL

#' SCBI GEDTM30 sample raster
#'
#' A 30 m GEDTM30 GeoTIFF downloaded for the example boundary. Elevation
#' values are expressed in metres.
#'
#' @format A one-band GeoTIFF stored in
#'   `inst/extdata/GEDTM30_API_original.tif`. Horizontal CRS: WGS 84
#'   (EPSG:4326); nominal sample spacing: approximately 30 metres.
#' @docType data
#' @keywords datasets
#' @name scbi_gedtm30
#' @examples
#' dem_path <- system.file(
#'   "extdata", "GEDTM30_API_original.tif",
#'   package = "dem30mDownloadR"
#' )
#' @source OpenTopography Global DEM API, GEDTM30 dataset:
#'   \url{https://portal.opentopography.org/}
NULL
