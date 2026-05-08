test_that("bayes returns correct posterior probability", {
  result <- bayes(0.07, 0.92, 0.07)
  expect_type(result, "list")
  expect_true("posterior_probability" %in% names(result))
  expect_equal(result$posterior_probability, 0.5, tolerance = 1e-6)
})

test_that("contingency table is computed correctly", {
  result <- bayes(0.07, 0.92, 0.07, index = 1000)
  tbl <- result$contingency_table
  
  # True Positives: 0.92 * 0.07 * 1000 = 64.4
  expect_equal(tbl$Disease[1], 64.4, tolerance = 0.1)
  
  # False Positives: 0.07 * 0.93 * 1000 = 65.1
  expect_equal(tbl$`No Disease`[1], 65.1, tolerance = 0.1)
  
  # True Negatives: 0.93 * 0.93 * 1000 = 864.9
  expect_equal(tbl$`No Disease`[2], 864.9, tolerance = 0.1)
  
  # False Negatives: 0.08 * 0.07 * 1000 = 5.6
  expect_equal(tbl$Disease[2], 5.6, tolerance = 0.1)
})

test_that("visualizations are ggplot objects", {
  result <- bayes(0.07, 0.92, 0.07)
  
  expect_s3_class(result$barchart, "ggplot")
  expect_s3_class(result$heatmap, "ggplot")
  expect_s3_class(result$posterior_plot, "ggplot")
})

test_that("bayes handles percentage strings", {
  result <- bayes("7%", "92%", "7%")
  expect_true(is.numeric(result$posterior_probability))
  expect_equal(result$posterior_probability, 0.5, tolerance = 1e-6)
})

test_that("bayes validates inputs", {
  expect_error(bayes(-1, 0.92, 0.07))
  expect_error(bayes(0.07, 200, 0.07))
  expect_error(bayes(0.07, 0.92, 0.07, index = -10))
})

test_that("edge cases compute correctly", {
  # Prevalence = 0 → posterior must be 0
  result0 <- bayes(0, 0.92, 0.07)
  expect_equal(result0$posterior_probability, 0)
  
  # Prevalence = 1 → posterior must be 1
  result1 <- bayes(1, 0.92, 0.07)
  expect_equal(result1$posterior_probability, 1)
  
  # Sensitivity = 1
  result_sens1 <- bayes(0.07, 1, 0.07)
  expect_true(result_sens1$posterior_probability > 0)
  
  # False positive = 0
  result_fp0 <- bayes(0.07, 0.92, 0)
  expect_true(result_fp0$posterior_probability > 0.9)
  
  # Index = 1
  result_idx1 <- bayes(0.07, 0.92, 0.07, index = 1)
  expect_equal(nrow(result_idx1$contingency_table), 2)
})

test_that("returned object contains all expected elements", {
  result <- bayes(0.07, 0.92, 0.07)
  
  expected_names <- c(
    "posterior_probability",
    "contingency_table",
    "barchart",
    "heatmap",
    "posterior_plot"
  )
  
  expect_true(all(expected_names %in% names(result)))
})
