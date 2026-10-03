# =============================================================================
# Purpose:      Static analysis of one parsed student script (packages, set.seed placement, hard-coded paths, error classification). Nothing from the student file is executed.
# Author:       Matthew C. Vanderbilt
# Created:      2026-10-03
# Modified:     2026-10-03
# Tags:         [TO CONFIRM against code-library root TAGS.md] education; grading; code-evaluation
# Status:       draft
# Level:        intermediate
# AI-Assisted:  Yes - Claude (Anthropic). See AI-DISCLOSURE.md (pending).
# Dependencies: base R; stats (aggregate in report.R)
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

grader_default_rng_fns <- c(
  "sample", "sample.int", "runif", "rnorm", "rbinom", "rpois", "rexp", "rgamma", "rbeta",
  "rt", "rchisq", "rweibull", "rlogis", "rcauchy", "rgeom", "rhyper", "rnbinom",
  "rmultinom", "rlnorm", "rsignrank", "rwilcox", "rf", "sample_n", "sample_frac",
  "slice_sample", "initial_split", "createDataPartition", "createFolds", "vfold_cv",
  "rmvnorm", "kmeans", "randomForest", "rbernoulli", "rdunif"
)

# file-argument locations: c(argument name, position among unnamed args)
grader_io_specs <- list(
  read.csv = c("file", 1), read.csv2 = c("file", 1), read.delim = c("file", 1),
  read.table = c("file", 1), read_csv = c("file", 1), read_csv2 = c("file", 1),
  read_delim = c("file", 1), read_tsv = c("file", 1), fread = c("file", 1),
  read_excel = c("path", 1), read_xlsx = c("path", 1), read.xlsx = c("xlsxFile", 1),
  readRDS = c("file", 1), read_rds = c("file", 1), load = c("file", 1),
  readLines = c("con", 1), source = c("file", 1),
  write.csv = c("file", 2), write.csv2 = c("file", 2), write.table = c("file", 2),
  write_csv = c("file", 2), write_xlsx = c("path", 2), write.xlsx = c("file", 2),
  saveRDS = c("file", 2), write_rds = c("path", 2), save = c("file", NA),
  ggsave = c("filename", 1), writeLines = c("con", 2), sink = c("file", 1),
  setwd = c("dir", 1)
)

grader_find_io_arg <- function(e, argname, pos) {
  a <- tryCatch(as.list(e)[-1], error = function(err) list())
  nm <- names(a); if (is.null(nm)) nm <- rep("", length(a))
  if (argname %in% nm) return(a[[which(nm == argname)[1]]])
  un <- a[nm == ""]
  if (!is.na(pos) && length(un) >= pos) return(un[[pos]])
  NULL
}

# literal string / composed-only-of-literals  => "literal"; anything with a
# variable or a computed value (getwd(), here(), etc.) => "variable"
grader_classify_arg <- function(x) {
  none <- list(kind = "none", text = "")
  ok <- tryCatch({
    if (is.null(x)) return(none)
    if (is.character(x)) return(list(kind = "literal", text = x[1]))
    if (is.symbol(x)) return(list(kind = "variable", text = ""))
    FALSE
  }, error = function(e) NA)
  if (is.na(ok)) return(list(kind = "variable", text = ""))
  if (!is.call(x)) return(none)

  syms <- character(); heads <- character(); strs <- character()
  collect <- function(z) {
    if (is.symbol(z)) {
      syms <<- c(syms, as.character(z))
    } else if (is.character(z)) {
      strs <<- c(strs, z)
    } else if (is.call(z)) {
      if (is.symbol(z[[1]])) heads <<- c(heads, as.character(z[[1]]))
      for (i in seq_along(z)) {
        if (i == 1) next
        if (identical(z[[i]], quote(expr = ))) next
        collect(z[[i]])
      }
    }
  }
  collect(x)
  combiners <- c("file.path", "paste", "paste0", "normalizePath", "sprintf", "c")
  if (length(syms) == 0 && all(heads %in% combiners) && length(strs)) {
    return(list(kind = "literal", text = paste(strs, collapse = "/")))
  }
  list(kind = "variable", text = "")
}

# TRUE for strings that look like a file path, file name, or URL.
# (Digits in round(), labels, column names etc. are NOT flagged.)
grader_is_pathlike <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x) || !nzchar(x)) return(FALSE)
  if (grepl("%", x, fixed = TRUE)) return(FALSE)
  grepl("^(https?|ftp)://", x, ignore.case = TRUE) ||
    grepl("^([A-Za-z]:[/\\\\]|\\\\\\\\|~[/\\\\]|\\.{1,2}[/\\\\]|/[A-Za-z0-9_.-]+/)", x) ||
    grepl("\\.(csv|tsv|txt|xlsx?|rds|rda|rdata|json|xml|sav|dta|sas7bdat|parquet|feather|png|jpe?g|pdf|html?|docx?|zip|r|rmd)$",
          x, ignore.case = TRUE)
}

grader_header_label <- function(line) {
  x <- gsub("^[#[:space:]]+", "", line)
  x <- sub("^[-=#]{3,}[[:space:]]*", "", x)
  x <- sub(",.*$", "", x)
  x <- sub("[[:space:]]*[-=#]{3,}.*$", "", x)
  trimws(x)
}

# Position (pre-order call counter) of the first call to any of `fnset`
# inside expression `e`; Inf if none. Function DEFINITIONS are skipped.
grader_first_call_pos <- function(e, fnset) {
  counter <- 0L
  found <- Inf
  visit <- function(x) {
    if (is.finite(found) || !is.call(x)) return(invisible())
    counter <<- counter + 1L
    h <- x[[1]]
    nm <- NA_character_
    if (is.symbol(h)) {
      nm <- as.character(h)
    } else if (is.call(h) && length(h) == 3 && is.symbol(h[[1]]) &&
               as.character(h[[1]]) %in% c("::", ":::")) {
      nm <- as.character(h[[3]])
    }
    if (!is.na(nm) && nm == "function") return(invisible())
    if (!is.na(nm) && nm %in% fnset) { found <<- counter; return(invisible()) }
    for (i in seq_along(x)) {
      if (i == 1 && is.symbol(h)) next
      if (identical(x[[i]], quote(expr = ))) next
      visit(x[[i]])
    }
  }
  visit(e)
  found
}

# Names assigned (plain `x <- ...`, assign("x"), for-loop variable) and names used in one expression.
grader_expr_symbols <- function(e) {
  assigned <- character(); used <- character()
  visit <- function(x) {
    if (is.symbol(x)) { used <<- c(used, as.character(x)); return(invisible()) }
    if (!is.call(x)) return(invisible())
    h <- x[[1]]
    if (is.symbol(h)) {
      hn <- as.character(h)
      if (hn %in% c("<-", "=", "<<-") && length(x) == 3 && is.symbol(x[[2]])) {
        assigned <<- c(assigned, as.character(x[[2]]))
        visit(x[[3]])
        return(invisible())
      }
      if (hn == "assign" && length(x) >= 2 && is.character(x[[2]])) assigned <<- c(assigned, x[[2]][1])
      if (hn == "for" && length(x) == 4 && is.symbol(x[[2]])) assigned <<- c(assigned, as.character(x[[2]]))
      used <<- c(used, hn)
    }
    for (i in seq_along(x)) {
      if (i == 1 && is.symbol(h)) next
      if (identical(x[[i]], quote(expr = ))) next
      visit(x[[i]])
    }
  }
  visit(e)
  list(assigned = unique(assigned), used = unique(used))
}

# Separates ROOT errors (own cause) from CASCADE errors (the expression uses an
# object/function that a failed earlier expression should have created).
grader_classify_errors <- function(idx, sc) {
  type <- rep("root", length(idx)); by <- rep(NA_integer_, length(idx))
  failed <- list()
  for (j in seq_along(idx)) {
    i <- idx[j]
    hit <- intersect(sc$expr_used[[i]], names(failed))
    root_i <- i
    if (length(hit)) { type[j] <- "cascade"; root_i <- failed[[hit[1]]]; by[j] <- root_i }
    for (a in sc$expr_assigned[[i]]) if (is.null(failed[[a]])) failed[[a]] <- root_i
  }
  data.frame(type = type, by = by, stringsAsFactors = FALSE)
}

# Minimal stand-in used if the static scan itself fails, so the script is still executed.
grader_empty_scan <- function(exprs) {
  n <- length(exprs); srefs <- attr(exprs, "srcref")
  first <- last <- rep(NA_integer_, n)
  if (!is.null(srefs)) for (i in seq_len(n)) {
    first[i] <- as.integer(srefs[[i]][1]); last[i] <- as.integer(srefs[[i]][3])
  }
  list(n_exprs = n,
       expr_info = data.frame(first = first, last = last, block = rep(1L, n), label = rep("", n),
                              stringsAsFactors = FALSE),
       loaded = character(), installed = character(), ns_used = character(), called = character(),
       defined = character(), other_reads = character(), dyn_load = FALSE, dyn_install = FALSE,
       seed_idx = integer(), rng_blocks = 0L, rng_missing_idx = integer(),
       io = data.frame(fn = character(), idx = integer(), kind = character(), text = character(), stringsAsFactors = FALSE),
       hc = data.frame(fn = character(), idx = integer(), text = character(), stringsAsFactors = FALSE),
       expr_assigned = rep(list(character()), n), expr_used = rep(list(character()), n))
}

grader_scan_script <- function(exprs, code_lines, is_rmd = FALSE,
                               rng_fns = grader_default_rng_fns) {
  n <- length(exprs)

  # ---- top-level expression positions, code blocks and labels ------
  srefs <- attr(exprs, "srcref")
  first <- last <- rep(NA_integer_, n)
  if (!is.null(srefs)) {
    for (i in seq_len(n)) {
      first[i] <- as.integer(srefs[[i]][1])
      last[i]  <- as.integer(srefs[[i]][3])
    }
  }
  is_header <- grepl("^[[:space:]]*#.*(-{4,}|={4,}|#{4,})", code_lines)
  is_blank  <- grepl("^[[:space:]]*$", code_lines)
  hdr_idx   <- which(is_header)
  brk <- logical(n); label <- character(n)
  for (i in seq_len(n)) {
    if (is.na(first[i])) { brk[i] <- TRUE; next }
    prev_last <- if (i == 1 || is.na(last[i - 1])) 0L else last[i - 1]
    between <- if (first[i] - prev_last > 1) (prev_last + 1L):(first[i] - 1L) else integer()
    brk[i] <- (i == 1) || any(is_header[between]) || (!is_rmd && any(is_blank[between]))
    h <- hdr_idx[hdr_idx < first[i]]
    label[i] <- if (length(h)) grader_header_label(code_lines[max(h)]) else ""
  }
  block <- if (n) cumsum(brk) else integer()
  expr_info <- data.frame(first = first, last = last, block = block, label = label,
                          stringsAsFactors = FALSE)

  # ---- state filled in while walking the code ------------------------
  loaded <- installed <- ns_used <- called <- defined <- other_reads <- character()
  dyn_load <- FALSE; dyn_install <- FALSE
  io_fn <- character(); io_idx <- integer(); io_kind <- character(); io_text <- character()
  cur_idx <- NA_integer_
  hc_fn <- character(); hc_idx <- integer(); hc_text <- character()
  suppress_path <- FALSE
  consts <- new.env(parent = baseenv())      # constant character vectors only
  allowed <- c("c", "paste", "paste0", "unique", "sort", "rev", "setdiff", "union",
               "intersect", "character", "tolower", "toupper", "sprintf", "file.path", "(")
  apply_fns <- c("lapply", "sapply", "vapply", "walk", "map", "map_lgl", "map_chr",
                 "map_dbl", "map_int")
  other_read_fns <- c("read_excel", "read_xlsx", "read.xlsx", "readRDS", "read_rds", "load",
                      "read_json", "fromJSON", "read_sas", "read_sav", "read_dta",
                      "readLines", "scan", "dbConnect", "read_parquet", "read_feather")

  # TRUE only if `x` is built purely from literals, known constants and a few
  # harmless functions -> safe to evaluate. Student code is never run otherwise.
  safe_const <- function(x) {
    tryCatch({
      if (is.null(x) || is.character(x) || is.numeric(x) || is.logical(x)) return(TRUE)
      if (is.symbol(x)) return(exists(as.character(x), envir = consts, inherits = FALSE))
      if (is.call(x)) {
        h <- x[[1]]
        if (!is.symbol(h) || !(as.character(h) %in% allowed)) return(FALSE)
        args <- as.list(x)[-1]
        return(all(vapply(args, safe_const, logical(1))))
      }
      FALSE
    }, error = function(e) FALSE)
  }
  eval_const <- function(x) if (safe_const(x)) tryCatch(eval(x, consts), error = function(e) NULL) else NULL

  as_pkg <- function(x, char_only = FALSE) {
    if (!char_only && is.symbol(x)) return(as.character(x))
    val <- eval_const(x)
    if (is.character(val) && length(val)) val else "<dynamic>"
  }

  walk <- function(e) {
    if (is.call(e)) {
      head <- e[[1]]
      fn <- NA_character_
      if (is.symbol(head)) {
        fn <- as.character(head)
      } else if (is.call(head) && length(head) == 3 && is.symbol(head[[1]]) &&
                 as.character(head[[1]]) %in% c("::", ":::")) {
        fn <- as.character(head[[3]])
        ns_used <<- c(ns_used, as.character(head[[2]]))
      }
      skip_idx <- integer()

      if (!is.na(fn)) {
        if (fn %in% c("::", ":::")) {
          ns_used <<- c(ns_used, as.character(e[[2]]))
          return(invisible())
        }
        called <<- c(called, fn)

        # hard-coded file path / file name / URL passed straight into a function call
        if (!suppress_path && !(fn %in% c("<-", "=", "<<-"))) {
          for (i in seq_along(e)) {
            if (i == 1) next
            if (identical(e[[i]], quote(expr = ))) next
            if (grader_is_pathlike(e[[i]])) {
              hc_fn <<- c(hc_fn, fn); hc_idx <<- c(hc_idx, cur_idx); hc_text <<- c(hc_text, e[[i]])
            }
          }
        }

        # assignments: track constant character vectors + function definitions
        if (fn %in% c("<-", "=", "<<-") && length(e) == 3 && is.symbol(e[[2]])) {
          nm <- as.character(e[[2]]); rhs <- e[[3]]
          if (is.call(rhs) && is.symbol(rhs[[1]]) && as.character(rhs[[1]]) == "function") {
            defined <<- c(defined, nm)
          }
          val <- eval_const(rhs)
          if (is.character(val)) {
            assign(nm, val, envir = consts)
          } else if (exists(nm, envir = consts, inherits = FALSE)) {
            rm(list = nm, envir = consts)
          }
          if (safe_const(rhs)) {          # plain value stored in a variable = recommended practice
            suppress_path <<- TRUE
            walk(rhs)
            suppress_path <<- FALSE
            return(invisible())
          }
        }

        # for (p in pkgs) { library(p, character.only = TRUE) }
        if (fn == "for" && length(e) == 4 && is.symbol(e[[2]])) {
          v <- as.character(e[[2]])
          if (exists(v, envir = consts, inherits = FALSE)) rm(list = v, envir = consts)
          vals <- eval_const(e[[3]])
          if (is.character(vals)) assign(v, vals, envir = consts)
          walk(e[[4]])
          if (exists(v, envir = consts, inherits = FALSE)) rm(list = v, envir = consts)
          return(invisible())
        }

        # lapply(pkgs, library, character.only = TRUE) / sapply(pkgs, function(p) ...)
        if (fn %in% apply_fns) {
          a  <- tryCatch(as.list(e)[-1], error = function(err) list())
          nm <- names(a); if (is.null(nm)) nm <- rep("", length(a))
          pick_arg <- function(names_, pos) {
            hit <- which(nm %in% names_)
            if (length(hit)) return(hit[1])
            un <- which(nm == "")
            if (length(un) >= pos) un[pos] else NA_integer_
          }
          xi <- pick_arg(c("X", ".x"), 1); fi <- pick_arg(c("FUN", ".f"), 2)
          if (!is.na(xi) && !is.na(fi)) {
            vals <- eval_const(a[[xi]])
            fa <- a[[fi]]
            if (is.symbol(fa) && as.character(fa) %in% c("library", "require", "install.packages")) {
              pk <- if (is.character(vals)) vals else "<dynamic>"
              if (as.character(fa) == "install.packages") {
                installed <<- c(installed, pk)
                if (!is.character(vals)) dyn_install <<- TRUE
              } else {
                loaded <<- c(loaded, pk)
              }
              skip_idx <- fi + 1L
            } else if (is.call(fa) && is.symbol(fa[[1]]) && as.character(fa[[1]]) == "function" &&
                       is.character(vals)) {
              pn <- names(fa[[2]])
              if (length(pn)) {
                assign(pn[1], vals, envir = consts)
                walk(fa[[3]])
                rm(list = pn[1], envir = consts)
                skip_idx <- fi + 1L
              }
            }
          }
        }

        if (fn %in% c("library", "require")) {
          mc <- tryCatch(match.call(base::library, e), error = function(err) NULL)
          if (!is.null(mc) && !is.null(mc$package)) {
            loaded <<- c(loaded, as_pkg(mc$package, isTRUE(mc$character.only)))
          }
        } else if (fn == "install.packages") {
          mc <- tryCatch(match.call(utils::install.packages, e), error = function(err) NULL)
          if (!is.null(mc) && !is.null(mc$pkgs)) {
            pk <- as_pkg(mc$pkgs, TRUE)
            installed <<- c(installed, pk)
            if ("<dynamic>" %in% pk) dyn_install <<- TRUE
          }
        } else if (fn %in% c("install_github", "install_version", "install_cran")) {
          a <- tryCatch(as.list(e)[-1], error = function(err) list())
          if (length(a)) {
            v <- as_pkg(a[[1]], TRUE)
            installed <<- c(installed, sub("^.*/", "", sub("@.*$", "", v)))
          }
        } else if (fn %in% c("p_load", "p_install")) {
          a  <- tryCatch(as.list(e)[-1], error = function(err) list())
          nm <- names(a); if (is.null(nm)) nm <- rep("", length(a))
          pk <- tryCatch(unlist(lapply(a[nm == ""], function(x) {
            if (is.symbol(x)) as.character(x) else if (is.character(x)) x else "<dynamic>"
          })), error = function(err) "<dynamic>")
          if ("char" %in% nm) pk <- c(pk, as_pkg(a[["char"]], TRUE))
          loaded    <<- c(loaded, pk)
          installed <<- c(installed, "pacman", pk)
        } else if (fn %in% other_read_fns) {
          other_reads <<- c(other_reads, fn)
        }

        spec <- grader_io_specs[[fn]]
        if (!is.null(spec)) {
          cls <- grader_classify_arg(grader_find_io_arg(e, spec[1], suppressWarnings(as.integer(spec[2]))))
          io_fn <<- c(io_fn, fn); io_idx <<- c(io_idx, cur_idx)
          io_kind <<- c(io_kind, cls$kind); io_text <<- c(io_text, cls$text)
        }
      }

      for (i in seq_along(e)) {
        if (i == 1 && is.symbol(head)) next
        if (i %in% skip_idx) next
        if (identical(e[[i]], quote(expr = ))) next
        walk(e[[i]])
      }
    } else if (is.symbol(e)) {
      # library/require handed over as a value we could not resolve
      if (as.character(e) %in% c("library", "require")) dyn_load <<- TRUE
    }
    invisible()
  }

  for (i in seq_len(n)) { cur_idx <- i; walk(exprs[[i]]) }
  if ("<dynamic>" %in% loaded) dyn_load <- TRUE

  # ---- seed / random-number blocks ------------------------------------
  seed_idx <- integer(); rng_blocks <- 0L; rng_missing_idx <- integer()
  for (b in unique(block)) {
    idx <- which(block == b)
    seeded <- FALSE; has_rng <- FALSE; flagged <- FALSE
    for (i in idx) {
      sp <- grader_first_call_pos(exprs[[i]], "set.seed")
      rp <- grader_first_call_pos(exprs[[i]], rng_fns)
      if (is.finite(sp)) seed_idx <- c(seed_idx, i)
      if (is.finite(rp)) {
        has_rng <- TRUE
        if (!seeded && !(is.finite(sp) && sp < rp) && !flagged) {
          flagged <- TRUE
          rng_missing_idx <- c(rng_missing_idx, i)
        }
      }
      if (is.finite(sp)) seeded <- TRUE
    }
    if (has_rng) rng_blocks <- rng_blocks + 1L
  }

  sym <- lapply(seq_len(n), function(i) grader_expr_symbols(exprs[[i]]))
  io <- data.frame(fn = io_fn, idx = io_idx, kind = io_kind, text = io_text,
                   stringsAsFactors = FALSE)
  hc <- data.frame(fn = hc_fn, idx = hc_idx, text = hc_text, stringsAsFactors = FALSE)

  list(
    n_exprs = n, expr_info = expr_info,
    loaded = unique(loaded), installed = unique(installed), ns_used = unique(ns_used),
    called = unique(called), defined = unique(defined), other_reads = unique(other_reads),
    dyn_load = dyn_load, dyn_install = dyn_install,
    seed_idx = seed_idx, rng_blocks = rng_blocks, rng_missing_idx = rng_missing_idx,
    io = io, hc = hc,
    expr_assigned = lapply(sym, function(z) z$assigned),
    expr_used = lapply(sym, function(z) z$used)
  )
}

# Maps line numbers of purled code back to the original .Rmd (chunk order is
# preserved by knitr::purl). Falls back to purled line numbers if chunk counts differ.
grader_map_rmd_lines <- function(info, rmd_lines, code_lines) {
  info$src_first <- info$first; info$src_last <- info$last; info$note <- ""
  fences  <- grep("^[[:space:]]*`{3,}[[:space:]]*\\{[[:space:]]*[rR]([ ,}]|$)", rmd_lines)
  headers <- grep("^##[[:space:]]*-{4}", code_lines)
  if (!length(fences) || length(fences) != length(headers) || !nrow(info)) {
    info$note <- "purled"
    return(info)
  }
  h  <- vapply(info$first, function(l) sum(headers < l), integer(1))
  ok <- !is.na(h) & h >= 1
  info$src_first[ok] <- fences[h[ok]] + (info$first[ok] - headers[h[ok]])
  info$src_last[ok]  <- fences[h[ok]] + (info$last[ok]  - headers[h[ok]])
  info
}
