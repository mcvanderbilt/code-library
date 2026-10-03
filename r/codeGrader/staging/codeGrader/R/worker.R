# =============================================================================
# Purpose:      Runs ONE student script in its own fresh R process (via callr): preloads approved packages, neutralizes risky calls, redirects data imports, runs expression by expression.
# Author:       Matthew C. Vanderbilt
# Created:      2026-10-03
# Modified:     2026-10-03
# Tags:         [TO CONFIRM against code-library root TAGS.md] education; grading; code-evaluation
# Status:       draft
# Level:        intermediate
# AI-Assisted:  Yes - Claude (Anthropic). See AI-DISCLOSURE.md (pending).
# Dependencies: callr; utils, grDevices (inside the worker process)
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

grader_worker <- function(code_path, data_file, approved, base_pkgs, fn_names,
                          expr_timeout_sec, seed_value, seed_inject_idx) {

  out <- list(preload_failed = character(), fn_pkg = character(), errors = list(),
              n_ok = 0L, n_warn = 0L, n_exprs = NA_integer_, elapsed = NA_real_,
              blocked = character(), reads = 0L, files_written = character())

  # ---- 1. load every approved package ---------------------------------
  for (p in approved) {
    ok <- tryCatch({
      suppressWarnings(suppressPackageStartupMessages(
        library(p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)))
      TRUE
    }, error = function(e) FALSE)
    if (!ok) out$preload_failed <- c(out$preload_failed, p)
  }

  # ---- 2. which package does each called function resolve to? ---------
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
  if ("readr" %in% approved && !("readr" %in% out$preload_failed)) {
    for (nm in c("read_csv", "read_delim")) assign(nm, all_readers[[nm]], envir = env)
  }
  if ("data.table" %in% approved && !("data.table" %in% out$preload_failed)) {
    assign("fread", all_readers[["fread"]], envir = env)
  }

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
  grDevices::graphics.off()
  out$blocked <- ctx$blocked
  out$reads   <- ctx$reads
  out$files_written <- setdiff(list.files(getwd(), recursive = TRUE), basename(data_file))
  out
}

# One-time: which packages does each approved package attach? (e.g., tidyverse
# attaches dplyr, ggplot2, ...). Used to avoid false "package not loaded" flags.
grader_attach_map <- function(pkgs) {
  out <- list()
  for (p in pkgs) {
    res <- tryCatch(callr::r(function(p) {
      before <- search()
      suppressWarnings(suppressPackageStartupMessages(
        library(p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)))
      sub("^package:", "", setdiff(search(), before))
    }, args = list(p = p), timeout = 120), error = function(e) NULL)
    out[[p]] <- unique(c(p, res))
  }
  out
}
