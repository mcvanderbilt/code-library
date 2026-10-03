test_that("append writes the header once and appends later rows", {
  d <- withr::local_tempdir(); p <- file.path(d, "res.csv")
  grader_append_csv(data.frame(a = 1:2, b = c("x", "y")), p)
  grader_append_csv(data.frame(a = 3L, b = "z"), p)
  expect_equal(nrow(utils::read.csv(p)), 3)
  expect_equal(sum(readLines(p) == '"a","b"'), 1)
})

test_that("a changed column layout goes to a separate file instead of corrupting the old one", {
  d <- withr::local_tempdir(); p <- file.path(d, "res.csv")
  grader_append_csv(data.frame(a = 1L, b = "x"), p)
  grader_append_csv(data.frame(a = 2L, c = "q"), p)
  expect_equal(nrow(utils::read.csv(p)), 1)
  expect_length(list.files(d, pattern = "newlayout"), 1)
})

test_that("worksheet names", {
  expect_equal(grader_sheet_name(3, "20261003_141530"), "Assignment 3")
  expect_equal(grader_sheet_name(2.5, "x"), "Assignment 2.5")
  expect_equal(grader_sheet_name(NULL, "20261003_141530"), "20261003_141530")
  expect_equal(grader_sheet_name(NA_real_, "20261003_141530"), "20261003_141530")
})

test_that("merging a refreshed sheet keeps instructor entries and extra columns", {
  res <- data.frame(file = c("a.R", "b.R"), status = c("Executed without error", "Executed with errors"),
                    feedback_text = c("f1", "f2"), file_role = "student", stringsAsFactors = FALSE)
  new <- grader_sheet_df(res)
  old <- data.frame(file = c("a.R", "c.R"), status = c("old", "old"),
                    instructor_score = c(9, 7), instructor_comments = c("good", NA),
                    feedback_text = c("o1", "o3"), file_role = "student",
                    my_extra = c("x", "y"), stringsAsFactors = FALSE)
  m <- grader_merge_sheet(old, new)
  expect_setequal(m$file, c("a.R", "b.R", "c.R"))
  expect_equal(m$instructor_score[m$file == "a.R"], 9)
  expect_equal(m$instructor_comments[m$file == "a.R"], "good")
  expect_equal(m$my_extra[m$file == "a.R"], "x")
  expect_equal(m$status[m$file == "a.R"], "Executed without error")   # refreshed
  expect_equal(m$feedback_text[m$file == "a.R"], "f1")
})

test_that("draft feedback reflects the findings", {
  r <- grader_row_template()
  r$status <- "Executed without error"
  expect_match(grader_feedback_text(r), "ran from start to finish")
  r$status <- "Executed with errors"; r$n_root_errors <- 2L; r$n_cascade_errors <- 1L
  r$root_error_summary <- "line 3: oops"
  expect_match(grader_feedback_text(r), "2 independent error")
  r$pkgs_unapproved <- "foo"
  expect_match(grader_feedback_text(r), "not on the approved list")
})

test_that("class summary counts students and ignores the instructor solution", {
  res <- data.frame(file_role = c("student", "student", "instructor_solution"),
                    file = c("a.R", "b.R", "key.R"),
                    status = c("Executed without error", "Executed with errors", "Executed without error"),
                    library_flags = "", other_flags = "", runtime_sec = c(1, 2, 1),
                    pkgs_unapproved = "", pkgs_necessary_not_loaded = "",
                    rng_blocks_missing_seed = "", hardcoded_calls = "", stringsAsFactors = FALSE)
  cs <- grader_class_summary(res, NULL, "r1", 3)
  expect_equal(cs$n[cs$item == "student files graded"], 2L)
  expect_true(all(c("overview", "status") %in% cs$section))
})
