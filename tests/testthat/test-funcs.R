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
