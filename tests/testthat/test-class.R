test_that("validationLog default values", {
  test_log <- validationLog$new()

  expect_equal(
    c(
      test_log$msg,
      test_log$result,
      test_log$dat,
      test_log$raw_dat,
      test_log$edit_dat
    ),
    c("", NULL, NULL, NULL, NULL, "")
  )
})


test_that("validationLog$msg works", {
  test_log <- validationLog$new()
  test_log$msg <- "foo"

  expect_equal(test_log$msg, "foo")
})


test_that("validationLog$catch_msg works", {
  # Define var
  test_log <- validationLog$new()

  test_fun <- function() {
    message("This is a message")

    "This is the result"
  }

  # Test - run catch_msg
  test_log$catch_msg(test_fun())

  expect_equal(
    c(test_log$msg, test_log$result),
    c("This is a message", "This is the result")
  )

  # Test - run catch_msg again
  test_log$catch_msg(test_fun())

  expect_equal(
    c(test_log$msg, test_log$result),
    c("This is a message\nThis is a message", "This is the result")
  )
})

test_that("validationLog$fl_upload works", {
  # Define var
  test_log <- validationLog$new()
  test_sitdat <- system.file(
    "extdata",
    "ExampleSites.xlsx",
    package = "MassWateR"
  )

  # Test
  test_log$fl_upload(
    file = test_sitdat,
    read_function = readMWRsites,
    data_name = "sitdat"
  )

  expect_equal(
    test_log$msg,
    paste0(
      "Running checks on site metadata...\n\n\tChecking column names... OK",
      "\n\tChecking all required columns are present... OK",
      "\n\tChecking for missing latitude or longitude values... OK",
      "\n\tChecking for non-numeric values in latitude... OK",
      "\n\tChecking for non-numeric values in longitude... OK",
      "\n\tChecking for positive values in longitude... OK",
      "\n\tChecking for missing entries for Monitoring Location ID... OK",
      "\n\nAll checks passed!"
    )
  )
  expect_equal(data.frame(test_log$dat, check.names = FALSE), tst$sitdat)
  expect_equal(test_log$raw_dat, NULL)
  expect_equal(test_log$edit_dat, "")
})


test_that("validationLog$from_format_upload works", {
  # Define var
  test_log <- validationLog$new()

  # Test
  test_log$from_format_upload(
    df = tst$sitdat,
    retry_fn = retry_fns$sitdat,
    data_name = "sitdat"
  )

  expect_equal(
    test_log$msg,
    paste0(
      "Running checks on site metadata...\n\n\tChecking column names... OK",
      "\n\tChecking all required columns are present... OK",
      "\n\tChecking for missing latitude or longitude values... OK",
      "\n\tChecking for non-numeric values in latitude... OK",
      "\n\tChecking for non-numeric values in longitude... OK",
      "\n\tChecking for positive values in longitude... OK",
      "\n\tChecking for missing entries for Monitoring Location ID... OK",
      "\n\nAll checks passed!"
    )
  )
  expect_equal(
    test_log$dat,
    tst$sitdat
  )
  expect_equal(test_log$raw_dat, NULL)
  expect_equal(test_log$edit_dat, "")
})
