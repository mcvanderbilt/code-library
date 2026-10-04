# Tests for parse recovery and error de-duplication (no student code is executed)

test_that("parse recovery skips only the broken expression and keeps line numbers", {
  lines <- c("a <- 1",
             "drive counts <- 2",                      # syntax error, line 2
             "b <- a + 1",
             "plot(a,",                                 # unclosed call: lines 4-6 skipped
             "  main = 'x'",
             "text(1, 1)",
             "c <- b + 1")
  pr <- grader_parse_recover(lines, "student.R")
  expect_equal(nrow(pr$errors), 2L)
  expect_equal(pr$errors$first, c(2L, 4L))
  expect_equal(pr$errors$last,  c(2L, 6L))
  expect_match(pr$errors$message[1], "^line 2: unexpected symbol")
  expect_match(pr$errors$message[2], "^lines 4-6: ")
  expect_false(any(grepl("<text>", pr$errors$message)))
  expect_length(pr$clean_lines, length(lines))       # line numbers preserved
  expect_true(all(startsWith(pr$clean_lines[c(2, 4:6)], "#")))
  expect_length(pr$exprs, 3L)                         # a, b, c survive
  srefs <- attr(pr$exprs, "srcref")
  expect_equal(vapply(srefs, function(s) as.integer(s[1]), integer(1)), c(1L, 3L, 7L))
  expect_equal(attr(srefs[[1]], "srcfile")$filename, "student.R")
})

test_that("an expression never closed before the end of file is reported once", {
  pr <- grader_parse_recover(c("x <- 1", "y <- c(1, 2,"), "f.R")
  expect_equal(nrow(pr$errors), 1L)
  expect_equal(pr$errors$first, 2L)
  expect_length(pr$exprs, 1L)
})

test_that("a clean file produces no syntax errors and the same expressions as parse()", {
  lines <- c("x <- 1", "y <- x +", "  2", "z <- function(a) {", "  a * 2", "}")
  pr <- grader_parse_recover(lines, "f.R")
  expect_equal(nrow(pr$errors), 0L)
  expect_length(pr$exprs, 3L)
  expect_identical(pr$clean_lines, lines)
})

test_that("a smart-quote or fully broken file still returns a usable result", {
  pr <- grader_parse_recover(c("x <- “hello”", "y <- 2"), "f.R")
  expect_equal(nrow(pr$errors), 1L)
  expect_length(pr$exprs, 1L)
})
