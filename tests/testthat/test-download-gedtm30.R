test_that("sample boundary supports a dry run", {
  boundary <- system.file("extdata", "boundary_buffer.geojson",
                          package = "dem30mDownloadR")
  expect_true(file.exists(boundary))
  result <- download_gedtm30(boundary, "not-read-in-dry-run.txt",
                              dry_run = TRUE)
  expect_equal(result$parameters$demtype, "GEDTM30")
  expect_equal(result$resolution_m, 30)
  expect_null(result$output_path)
})

test_that("invalid resolution is rejected", {
  boundary <- system.file("extdata", "boundary_buffer.geojson",
                          package = "dem30mDownloadR")
  expect_error(download_gedtm30(boundary, "key.txt", resolution_m = 0),
               "positive")
})
