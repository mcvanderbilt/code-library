# =============================================================================
# Purpose:      Runs ONE student script in its own fresh R process (via callr): attaches the packages the student loaded (in their order), neutralizes risky calls, redirects data imports, runs expression by expression.
# Author:       Matthew C. Vanderbilt (@mcvanderbilt)
# Created:      2026-10-03
# Modified:     2026-10-03 — Attach only the student's own library() packages in their order; export map built with the attach map; dev.off()/graphics.off() stand-ins and devices-left-open count
# Version:      1.7.0
# Tags:         automation, data-validation, reporting, teaching
# Status:       draft
# Level:        intermediate
# AI-Assisted:  generated (Claude) — see code-library AI-DISCLOSURE.md
# Dependencies: callr; utils, grDevices (inside the worker process)
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

grader_worker <- function(code_path, data_file, approved, base_pkgs, fn_names,
                          expr_timeout_sec, seed_value, seed_inject_idx,
                          student_pkgs = character()) {

  out <- list(preload_failed = character(), fn_pkg = character(), errors = list(),
              n_ok = 0L, n_warn = 0L, n_exprs = NA_integer_, elapsed = NA_real_,
              blocked = character(), reads = 0L, files_written = character(),
              attached = character(), devices_left_open = 0L)

  # ---- 1. attach the packages the STUDENT loads, in the student's order --
  # Only approved packages the student's own library()/require() calls name
  # are attached (the caller intersects the scanned list with the approved
  # list). Attaching them in the student's order reproduces the student's
  # search path, so masking (e.g. mosaic::sd over stats::sd) and missing
  # packages behave exactly as they would when the student runs the script.
  for (p in student_pkgs) {
    ok <- tryCatch({
      suppressWarnings(suppressPackageStartupMessages(
        library(p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)))
      TRUE
    }, error = function(e) FALSE)
    if (!ok) out$preload_failed <- c(out$preload_failed, p)
  }
  out$attached <- sub("^package:", "", grep("^package:", search(), value = TRUE))

  # ---- 2. which package does each called function resolve to? ---------
  # NA = not found on the student's search path (the call will fail with
  # "could not find function"); the main session then looks the name up in
  # the approved packages' export map to say WHICH package was not loaded.
  if (length(fn_names)) {
    out$fn_pkg <- vapply(fn_names, function(fn) {
      f <- tryCatch(utils::find(fn, mode = "function"), error = function(e) character())
      f <- f[f != ".GlobalEnv"]
      if (length(f)) sub("^package:", "", f[1]) else NA_character_
    }, character(1))
  }

  # ---- 3. sandbox ------------------------------------------------------
  ctx <- new.env()
  ctx$blocked <- character(); ctx$reads <- 0L

  mk_blocked <- function(nm, value) {
    force(nm); force(value)
    function(...) { ctx$blocked <- c(ctx$blocked, nm); invisible(value) }
  }
  blocked <- list(
    # package installs / loads (student calls are never executed)
    library = NULL, require = TRUE,
    install.packages = NULL, update.packages = NULL, remove.packages = NULL,
    install_github = NULL, install_version = NULL, install_cran = NULL, install = NULL,
    p_load = NULL, p_install = NULL,
    # working directory / interactive file pickers
    setwd = NULL, file.choose = data_file, choose.files = data_file,
    choose.dir = dirname(data_file), readline = "", menu = 1L,
    # system access, deletion, network, exit, debugging
    system = NULL, system2 = NULL, shell = NULL, shell.exec = NULL,
    unlink = NULL, file.remove = NULL, quit = NULL, q = NULL,
    browseURL = NULL, download.file = NULL, View = NULL,
    browser = NULL, debug = NULL, debugonce = NULL
  )
  blocked_fns <- list()
  for (nm in names(blocked)) blocked_fns[[nm]] <- mk_blocked(nm, blocked[[nm]])

  # set.seed(): the call stays where the student put it, but always runs the
  # grader's STANDARD seed (never the student's value)
  blocked_fns[["set.seed"]] <- function(seed, ...) {
    ctx$blocked <- c(ctx$blocked, "set.seed")
    base::set.seed(seed_value)
    invisible(NULL)
  }

  # data imports -> always your data file. 'file' is never evaluated, so bad paths never matter.
  make_reader <- function(fun) {
    force(fun)
    function(file, ...) {
      ctx$reads <- ctx$reads + 1L
      fun(data_file, ...)
    }
  }
  all_readers <- list(
    read.csv   = make_reader(utils::read.csv),
    read.csv2  = make_reader(utils::read.csv2),
    read.delim = make_reader(utils::read.delim),
    read.table = make_reader(utils::read.table),
    read_csv   = make_reader(function(f, ...) readr::read_csv(f, ...)),
    read_delim = make_reader(function(f, ...) readr::read_delim(f, ...)),
    fread      = make_reader(function(f, ...) data.table::fread(f, ...))
  )

  env <- new.env(parent = globalenv())
  for (nm in names(blocked_fns)) assign(nm, blocked_fns[[nm]], envir = env)
  for (nm in c("read.csv", "read.csv2", "read.delim", "read.table")) assign(nm, all_readers[[nm]], envir = env)
  # readr / data.table readers are redirected only when the student actually
  # attached those packages (directly or via tidyverse); otherwise a bare
  # read_csv() fails with "could not find function", as it would for the student.
  if ("readr" %in% out$attached) {
    for (nm in c("read_csv", "read_delim")) assign(nm, all_readers[[nm]], envir = env)
  }
  if ("data.table" %in% out$attached) {
    assign("fread", all_readers[["fread"]], envir = env)
  }

  # Graphics devices. The grader keeps one null pdf device open so plots never
  # hit the screen. dev.off()/graphics.off() stand-ins behave as they would for
  # the student: closing when no student device is open is an error (R's own
  # message is "cannot shut down device 1 (the null device)"), and the grader's
  # device is never closed by student code.
  base_dev <- NULL
  assign("dev.off", function(which = grDevices::dev.cur()) {
    open <- setdiff(grDevices::dev.list(), base_dev)
    if (!length(open)) {
      stop("dev.off(): no graphics device is open to close (there is no matching png()/pdf()/jpeg() call before it)",
           call. = FALSE)
    }
    grDevices::dev.off(which)
  }, envir = env)
  assign("graphics.off", function() {
    for (d in setdiff(grDevices::dev.list(), base_dev)) grDevices::dev.off(d)
    invisible(NULL)
  }, envir = env)

  # pkg::fn -> block installers, enforce the approved list, redirect readers
  assign("::", function(pkg, name) {
    pkg <- as.character(substitute(pkg)); name <- as.character(substitute(name))
    if (name %in% names(blocked_fns)) return(blocked_fns[[name]])
    if (!(pkg %in% c(base_pkgs, approved))) {
      stop(sprintf("Package '%s' is not on the approved list", pkg), call. = FALSE)
    }
    if (name %in% names(all_readers) && pkg %in% c("utils", "readr", "data.table")) return(all_readers[[name]])
    getExportedValue(pkg, name)
  }, envir = env)
  assign(":::", function(pkg, name) {
    pkg <- as.character(substitute(pkg)); name <- as.character(substitute(name))
    if (name %in% names(blocked_fns)) return(blocked_fns[[name]])
    if (!(pkg %in% c(base_pkgs, approved))) {
      stop(sprintf("Package '%s' is not on the approved list", pkg), call. = FALSE)
    }
    get(name, envir = asNamespace(pkg))
  }, envir = env)

  # ---- 4. run expression by expression --------------------------------
  exprs <- parse(code_path, keep.source = TRUE, encoding = "UTF-8")
  out$n_exprs <- length(exprs)
  con <- file(file.path(getwd(), ".grader_console.txt"), open = "wt")
  sink(con)
  grDevices::pdf(NULL)
  base_dev <- grDevices::dev.cur()
  t0 <- Sys.time()

  for (i in seq_along(exprs)) {
    # random-number code with no earlier set.seed() in its block: run it ourselves
    if (i %in% seed_inject_idx) {
      base::set.seed(seed_value)
      ctx$blocked <- c(ctx$blocked, "set.seed_injected")
    }
    setTimeLimit(elapsed = expr_timeout_sec, transient = TRUE)
    err <- tryCatch({
      withCallingHandlers(
        eval(exprs[[i]], envir = env),
        warning = function(w) { out$n_warn <<- out$n_warn + 1L; invokeRestart("muffleWarning") },
        message = function(m) invokeRestart("muffleMessage"))
      NULL
    }, error = function(e) {
      cl <- conditionCall(e)
      fnn <- NA_character_; txt <- NA_character_
      if (!is.null(cl)) {
        txt <- substr(paste(deparse(cl, nlines = 1L), collapse = " "), 1, 80)
        h <- cl[[1]]
        if (is.symbol(h)) {
          fnn <- as.character(h)
        } else if (is.call(h) && length(h) == 3 && is.symbol(h[[1]]) &&
                   as.character(h[[1]]) %in% c("::", ":::")) {
          fnn <- as.character(h[[3]])
        }
      }
      internal <- c("eval", "evalq", "withCallingHandlers", "tryCatch", "doTryCatch",
                    "tryCatchList", "tryCatchOne", "eval.parent", "source", "sys.source")
      if (!is.na(fnn) && fnn %in% internal) fnn <- NA_character_
      list(i = i, message = gsub("\\s+", " ", conditionMessage(e)), fn = fnn, call = txt)
    })
    setTimeLimit(cpu = Inf, elapsed = Inf)
    if (is.null(err)) out$n_ok <- out$n_ok + 1L else out$errors[[length(out$errors) + 1L]] <- err
  }

  out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  while (sink.number() > 0) sink()
  close(con)
  out$devices_left_open <- length(setdiff(grDevices::dev.list(), base_dev))   # png()/pdf() never closed
  grDevices::graphics.off()
  out$blocked <- ctx$blocked
  out$reads   <- ctx$reads
  out$files_written <- setdiff(list.files(getwd(), recursive = TRUE), basename(data_file))
  out
}

# One-time, per approved package (each in a throw-away R process):
#   attach  - which packages does library(p) put on the search path?
#             (tidyverse attaches dplyr, ggplot2, ...). Used so that
#             library(tidyverse) counts as loading ggplot2, and so that a
#             separate library(ggplot2) after it is reported as redundant.
#   exports - which function names does p export? Used to name the package a
#             student forgot to load when a call could not be resolved.
grader_pkg_maps <- function(pkgs) {
  attach <- list(); exports <- list()
  for (p in pkgs) {
    res <- tryCatch(callr::r(function(p) {
      before <- search()
      suppressWarnings(suppressPackageStartupMessages(
        library(p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)))
      list(attached = sub("^package:", "", setdiff(search(), before)),
           exports  = getNamespaceExports(p))
    }, args = list(p = p), timeout = 120), error = function(e) NULL)
    attach[[p]]  <- unique(c(p, res$attached))
    exports[[p]] <- unique(res$exports)
  }
  list(attach = attach, exports = exports)
}

# Kept for callers that only need the attach map.
grader_attach_map <- function(pkgs) grader_pkg_maps(pkgs)$attach
