#' Download a 30 m GEDTM30 DEM for a polygon boundary
#'
#' @description
#' Reads an OpenTopography API key from a local text file, downloads the
#' GEDTM30 source raster for the bounding box of a polygon, and writes a
#' projected, buffered, masked GeoTIFF at the requested resolution.
#'
#' @param vector_path Path to a GeoJSON or an ESRI Shapefile polygon boundary.
#' @param api_key_path Path to a text file containing only the API key.
#' @param output_dir Directory where the output folder will be created.
#' @param buffer_m Buffer distance in metres around the dissolved boundary.
#' @param resolution_m Output pixel size in metres.
#' @param target_crs Optional projected CRS. If `NULL`, the appropriate UTM
#'   zone is selected from the boundary centroid.
#' @param dry_run If `TRUE`, validate inputs and print the request without
#'   downloading data.
#' @return A list containing the output paths, request parameters, CRS, and
#'   raster verification values. With `dry_run = TRUE`, download paths are
#'   `NULL`.
#' @examples
#' \dontrun{
#' result <- download_gedtm30(
#'   vector_path = "boundary.geojson",
#'   api_key_path = "OPENtopography_key.txt",
#'   output_dir = "dem-output"
#' )
#' }
#' @export
download_gedtm30 <- function(vector_path, api_key_path, output_dir = ".",
                             buffer_m = 60, resolution_m = 30,
                             target_crs = NULL, dry_run = FALSE) {
  stopifnot(length(vector_path) == 1L, length(api_key_path) == 1L,
            length(output_dir) == 1L)
  if (!file.exists(vector_path)) {
    stop("The vector boundary does not exist: ", vector_path, call. = FALSE)
  }
  if (!is.numeric(buffer_m) || length(buffer_m) != 1L || buffer_m < 0) {
    stop("buffer_m must be a non-negative number.", call. = FALSE)
  }
  if (!is.numeric(resolution_m) || length(resolution_m) != 1L ||
      resolution_m <= 0) {
    stop("resolution_m must be a positive number.", call. = FALSE)
  }

  boundary <- sf::st_read(vector_path, quiet = TRUE)
  if (is.na(sf::st_crs(boundary))) {
    stop("The vector boundary must have a coordinate reference system.",
         call. = FALSE)
  }
  boundary <- sf::st_make_valid(boundary)
  boundary <- boundary[!sf::st_is_empty(boundary), ]
  if (!nrow(boundary) ||
      !all(as.character(sf::st_geometry_type(boundary)) %in%
             c("POLYGON", "MULTIPOLYGON"))) {
    stop("The input must contain non-empty polygon geometries.", call. = FALSE)
  }
  boundary <- sf::st_transform(boundary, 4326)
  geographic <- sf::st_union(boundary)
  if (sf::st_is_longlat(geographic)) {
    bbox <- sf::st_bbox(geographic)
    if ((bbox["xmax"] - bbox["xmin"]) >= 180 ||
        bbox["ymin"] < -62.00875 || bbox["ymax"] > 83.68525) {
      stop("The boundary is outside the GEDTM30 geographic coverage.",
           call. = FALSE)
    }
  }

  centroid <- sf::st_coordinates(sf::st_centroid(geographic))
  zone <- min(60L, max(1L, floor((centroid[1] + 180) / 6) + 1L))
  if (is.null(target_crs)) {
    target_crs <- if (centroid[2] >= 0) 32600L + zone else 32700L + zone
  }
  projected <- sf::st_transform(geographic, target_crs)
  buffered <- sf::st_buffer(projected, buffer_m)
  buffered_wgs84 <- sf::st_transform(buffered, 4326)
  bb <- sf::st_bbox(buffered_wgs84)
  cell <- 1 / 3600
  params <- list(
    demtype = "GEDTM30",
    west = floor(bb["xmin"] / cell) * cell - cell,
    east = ceiling(bb["xmax"] / cell) * cell + cell,
    south = floor(bb["ymin"] / cell) * cell - cell,
    north = ceiling(bb["ymax"] / cell) * cell + cell,
    outputFormat = "GTiff"
  )
  if (params$south < -62.00875 || params$north > 83.68525 ||
      params$west < -180 || params$east > 180) {
    stop("The buffered boundary is outside the GEDTM30 coverage.",
         call. = FALSE)
  }

  left <- floor(sf::st_bbox(buffered)["xmin"] / resolution_m) * resolution_m
  bottom <- floor(sf::st_bbox(buffered)["ymin"] / resolution_m) * resolution_m
  right <- ceiling(sf::st_bbox(buffered)["xmax"] / resolution_m) * resolution_m
  top <- ceiling(sf::st_bbox(buffered)["ymax"] / resolution_m) * resolution_m
  width <- as.integer(round((right - left) / resolution_m))
  height <- as.integer(round((top - bottom) / resolution_m))
  if (width * height > 1e8) {
    stop("The requested output exceeds 100 million pixels.", call. = FALSE)
  }
  request <- list(
    endpoint = "https://portal.opentopography.org/API/globaldem",
    parameters = params, crs = target_crs, buffer_m = buffer_m,
    resolution_m = resolution_m, dimensions = c(width, height)
  )
  if (dry_run) {
    message("Dry run: ", jsonlite::toJSON(request, auto_unbox = TRUE))
    return(c(request, list(raw_path = NULL, output_path = NULL)))
  }
  if (!file.exists(api_key_path)) {
    stop("The API key file does not exist: ", api_key_path, call. = FALSE)
  }
  key <- trimws(readLines(api_key_path, warn = FALSE, encoding = "UTF-8"))
  key <- paste(key, collapse = "")
  if (!nzchar(key) || grepl("\\s", key)) {
    stop("The API key file must contain only the key.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  run_dir <- file.path(output_dir, paste0("GEDTM30_", tools::file_path_sans_ext(
    basename(vector_path)), "_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
  raw_path <- file.path(run_dir, "GEDTM30_API_original.tif")
  response <- httr2::request(request$endpoint) |>
    httr2::req_url_query(!!!params, API_Key = key) |>
    httr2::req_timeout(300) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()
  if (httr2::resp_status(response) != 200) {
    stop("OpenTopography returned HTTP ", httr2::resp_status(response), ".",
         call. = FALSE)
  }
  httr2::resp_body_raw(response) |> writeBin(raw_path)
  source_raster <- terra::rast(raw_path)
  if (terra::nlyr(source_raster) != 1L) {
    stop("The downloaded response does not contain one raster layer.",
         call. = FALSE)
  }
  target_template <- terra::rast(
    nrows = height, ncols = width,
    xmin = left, xmax = right, ymin = bottom, ymax = top,
    crs = sf::st_crs(target_crs)$wkt
  )
  projected_raster <- terra::project(source_raster, target_template,
                                     method = "bilinear")
  mask <- terra::vect(buffered)
  projected_raster <- terra::mask(projected_raster, mask,
                                  touches = TRUE, updatevalue = -9999)
  output_path <- file.path(run_dir, paste0(
    "GEDTM30_", resolution_m, "m_buffer", buffer_m, "m.tif"
  ))
  terra::writeRaster(projected_raster, output_path, overwrite = FALSE,
                     gdal = c("COMPRESS=DEFLATE", "TILED=YES"),
                     NAflag = -9999)
  list(raw_path = raw_path, output_path = output_path, request = request,
       crs = target_crs, dimensions = c(width, height),
       min_m = terra::global(projected_raster, "min", na.rm = TRUE)[1, 1],
       max_m = terra::global(projected_raster, "max", na.rm = TRUE)[1, 1])
}
