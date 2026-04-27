# -------------------------------------------------------------------------
# Purpose: Custom Function for Loading Multiple R Packages               --
# Author: Matthew C. Vanderbilt, MSBA                                    --
# Created: 6 November 2025                                               --
# Updated: 6 November 2025                                               --
# -------------------------------------------------------------------------

load_packages <- function(
  packages.to.load,
  run.updates = TRUE
) {

  # List Tidyverse packages to avoid redundant loading
  packages.tidyverse <- c(
    "ggplot2",           # advanced graphics
    "dplyr",             # data manipulation
    "tidyr",             # data tidying
    "readr",             # reads rectangular / structured data
    "purrr",             # functional programming
    "tibble",            # enhanced data frames
    "stringr",           # string manipulation
    "forcats",           # categorical data handling
    "lubridate"          # date-time handling
  )

  # Remove Tidyverse packages if Tidyverse is already present
  if ("tidyverse" %in% packages.to.load) {
    packages.to.load <- setdiff(
      packages.to.load,
      packages.tidyverse
    )
  }

  # Create and initialize return vectors
  loaded <- c()          # vector of successfully loaded packages
  failed <- c()          # vector of packages that failed to load
  updated <- c()         # vector of updated packages
  update.failed <- c()   # vector of packages that failed to update

  # Optional update of installed packages
  if (run.updates) {
    outdated <- suppressWarnings(
      old.packages()
    )
    if (!is.null(outdated)) {
      to_update <- intersect(
        rownames(outdated),
        packages.to.load
      )
      for (pkg in to_update) {
        message(paste("Attempting to update", pkg))
        tryCatch({
          suppressWarnings(
            update.packages(
              oldPkgs = pkg,
              ask = FALSE,
              checkBuilt = TRUE,
              quiet = TRUE
            )
          )
          updated <- c(updated, pkg)
        }, error = function(e) {
          message(paste("Failed to update", pkg, ":", e$message))
          update.failed <- c(update.failed, pkg)
        })
      }
    }
  }

  # Primary install/load loop through each package name in vector
  for (pkg in packages.to.load) {

    # Check if package exists on CRAN
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message(paste("Package", pkg, "not found on CRAN. Skipping."))
      failed <- c(failed, pkg)
      next
    }

    # Quietly install package if not already installed
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      tryCatch({
        suppressWarnings(
          install.packages(pkg, quiet = TRUE)
        )
        suppressPackageStartupMessages(
          library(
            pkg,
            character.only = TRUE,
            quietly = TRUE,
            warn.conflict = FALSE
          )
        )
        loaded <- c(loaded, pkg)
      }, error = function(e) {
        message(paste("Failed to install/load", pkg, ":", e$message))
        failed <- c(failed, pkg)
      })
    } else {
      suppressPackageStartupMessages(
        library(
          pkg,
          character.only = TRUE,
          quietly = TRUE,
          warn.conflict = FALSE
        )
      )
      loaded <- c(loaded, pkg)
    }
  }

  # Clean up temporary objects
  rm(                    # remove objects that are no longer needed
    pkg,
    packages.tidyverse
  )
  invisible(gc())

  # Conditional output
  if (length(loaded) > 0)        message("Loaded: ", paste(loaded, collapse = ", "))
  if (length(failed) > 0)        message("Failed: ", paste(failed, collapse = ", "))
  if (length(updated) > 0)       message("Updated: ", paste(updated, collapse = ", "))
  if (length(update.failed) > 0) message("Update failed: ", paste(update.failed, collapse = ", "))

  # Final success message
  message("Data libraries installed and loaded successfully.")

  # Return results invisibly
  invisible(
    list(
      loaded = loaded,
      failed = failed,
      updated = updated,
      update.failed = update.failed
   )
  )

}