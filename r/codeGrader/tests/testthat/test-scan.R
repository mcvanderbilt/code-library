# Tests for the static scanner (no student code is executed)

scan_text <- function(lines, is_rmd = FALSE) {
  ex <- parse(text = lines, keep.source = TRUE)
  grader_scan_script(ex, lines, is_rmd)
}

test_that("package vectors fed to for-loops and install.packages are resolved", {
  sc <- scan_text(c('pk <- c("dplyr", "ggplot2")',
                    'for (p in pk) library(p, character.only = TRUE)',
                    'install.packages(pk)'))
  expect_setequal(sc$loaded, c("dplyr", "ggplot2"))
  expect_setequal(sc$installed, c("dplyr", "ggplot2"))
  expect_false(sc$dyn_load)
})

test_that("lapply over a constant vector is resolved; unknown vectors are flagged", {
  sc <- scan_text(c('pk <- c("dplyr", "tidyr")', 'lapply(pk, library, character.only = TRUE)'))
  expect_setequal(sc$loaded, c("dplyr", "tidyr"))
  sc2 <- scan_text('lapply(get_pkgs(), library, character.only = TRUE)')
  expect_true(sc2$dyn_load)
})

test_that("set.seed placement is checked per code block", {
  expect_equal(scan_text("x <- rnorm(5)")$rng_missing_idx, 1L)
  expect_length(scan_text(c("set.seed(1)", "x <- rnorm(5)"))$rng_missing_idx, 0)
  # second block (after a blank line) has random code but no seed of its own
  sc <- scan_text(c("set.seed(1)", "x <- rnorm(5)", "", "y <- runif(3)"))
  expect_equal(sc$rng_missing_idx, 3L)
  # defining a function that contains random code is not random code being run
  expect_length(scan_text("f <- function() rnorm(1)")$rng_missing_idx, 0)
})

test_that("hard-coded paths are flagged; paths held in variables and round() digits are not", {
  sc <- scan_text(c('z <- read.csv("C:/Users/a/data.csv")',
                    'path <- "data/x.csv"',
                    'w <- read.csv(path)',
                    'r <- round(3.14159, 2)'))
  expect_true("C:/Users/a/data.csv" %in% sc$hc$text)
  expect_false("data/x.csv" %in% sc$hc$text)
  expect_false(any(sc$hc$fn == "round"))
})

test_that("path-like detector", {
  expect_true(grader_is_pathlike("C:/x/y.csv"))
  expect_true(grader_is_pathlike("https://example.com/data"))
  expect_true(grader_is_pathlike("results.xlsx"))
  expect_true(grader_is_pathlike("./data"))
  expect_false(grader_is_pathlike("hello"))
  expect_false(grader_is_pathlike("Male/Female"))
  expect_false(grader_is_pathlike("%Y/%m/%d"))
})

test_that("root errors are separated from cascade errors", {
  lines <- c("a <- 1", "b <- undefined_object + 1", "c2 <- b * 2", "d2 <- a + 1")
  sc <- scan_text(lines)
  cls <- grader_classify_errors(c(2L, 3L), sc)
  expect_equal(cls$type, c("root", "cascade"))
  expect_equal(cls$by, c(NA_integer_, 2L))
})
