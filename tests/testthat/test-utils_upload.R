test_that("detect_wrong_file works", {
  dat_results <- data.frame(
    "Activity Type" = NA,
    "Characteristic Name" = NA,
    "Result Value" = NA,
    check.names = FALSE
  )

  dat_nonsense <- data.frame(
    "foo" = NA,
    "bar" = NA
  )

  expect_null(
    detect_wrong_file(raw_df = NULL, data_name = "resdat")
  )
  expect_null(
    detect_wrong_file(raw_df = dat_results, data_name = "resdat")
  )
  expect_equal(
    detect_wrong_file(raw_df = dat_nonsense, data_name = "resdat"),
    "Error: Did you upload the wrong file? The column names do not match the expected format."
  )
  expect_equal(
    detect_wrong_file(raw_df = dat_results, data_name = "sitdat"),
    "Error: Did you upload the wrong file? This looks like it may be Results data."
  )
})

test_that("fl_status works", {
  expect_equal(
    fl_status(TRUE, NULL, NULL),
    HTML("<span style='color:#00A4CF'>Using test data</span>")
  )
  expect_equal(
    fl_status(FALSE, NULL, NULL),
    HTML("No file uploaded")
  )
  expect_equal(
    fl_status(FALSE, "foo", NULL),
    HTML("<span style='color:#f54242'>Error loading</span>")
  )
  expect_equal(
    fl_status(FALSE, NULL, "bar"),
    HTML("<span style='color:#64C147'>Loaded from format converter</span>")
  )
  expect_equal(
    fl_status(FALSE, "foo", "bar"),
    HTML("<span style='color:#64C147'>Data loaded</span>")
  )
})
