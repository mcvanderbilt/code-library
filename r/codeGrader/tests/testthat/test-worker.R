# Integration test: runs the real worker in a separate R process.

test_that("worker runs a clean script, redirects imports, and catches errors", {
  skip_on_cran()
  skip_if_not_installed("callr")
  td <- withr::local_tempdir()
  data_csv <- file.path(td, "data.csv")
  utils::write.csv(data.frame(x = 1:3), data_csv, row.names = FALSE)
  good <- file.path(td, "good.R")
  writeLines(c("library(stats)", 'd <- read.csv("C:/not/a/real/path.csv")', "x <- rnorm(3)",
               "stopifnot(nrow(d) == 3)", "y <- sum(d$x)"), good)
  bad <- file.path(td, "bad.R")
  writeLines(c("a <- 1", "b <- undefined_object + 1", "c2 <- b * 2", "d2 <- a + 1"), bad)

  run_worker <- function(path, inject = integer()) {
    rd <- file.path(td, paste0("run_", basename(path))); dir.create(rd)
    callr::r(grader_worker,
             args = list(code_path = path, data_file = data_csv, approved = character(),
                         base_pkgs = grader_base_pkgs, fn_names = c("sum", "rnorm"),
                         expr_timeout_sec = 30, seed_value = 123L, seed_inject_idx = inject),
             wd = rd, timeout = 120)
  }

  w1 <- run_worker(good, inject = 3L)
  expect_length(w1$errors, 0)
  expect_equal(w1$n_ok, 5L)
  expect_equal(w1$reads, 1L)
  expect_true(all(c("library", "set.seed_injected") %in% w1$blocked))
  expect_equal(unname(w1$fn_pkg["sum"]), "base")

  w2 <- run_worker(bad)
  expect_length(w2$errors, 2)
  expect_equal(w2$n_ok, 2L)
})
