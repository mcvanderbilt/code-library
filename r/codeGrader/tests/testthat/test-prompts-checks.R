test_that("seed validation accepts whole numbers in R's integer range only", {
  expect_true(grader_valid_seed("123"))
  expect_true(grader_valid_seed(" 42 "))
  expect_true(grader_valid_seed(-5))
  expect_true(grader_valid_seed("1e3"))
  expect_false(grader_valid_seed("abc"))
  expect_false(grader_valid_seed("1.5"))
  expect_false(grader_valid_seed(""))
  expect_false(grader_valid_seed("3e10"))
})

test_that("argument validation", {
  expect_true(grader_validate_args(3, 60, 300, NULL))
  expect_true(grader_validate_args(3, 60, 300, 4))
  expect_error(grader_validate_args(0, 60, 300, NULL))
  expect_error(grader_validate_args(3, 60, 30, NULL))
  expect_error(grader_validate_args(3, 60, 300, "a"))
})

test_that("git info is empty outside a repository", {
  gi <- grader_git_info(tempdir())
  expect_equal(gi$commit, "")
})

test_that("git repository finder returns NULL outside a repository", {
  expect_null(grader_in_git_repo(tempdir()))
})
