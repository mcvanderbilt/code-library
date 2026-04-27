# -------------------------------------------------------------------------
# Purpose: Custom Function for Loading Multiple R Packages
# Author: Matthew C. Vanderbilt, MSBA
# Created: 22 April 2026
# Updated: 27 April 2026
# -------------------------------------------------------------------------

export_data <- function(df) {
  
  # Dynamically select file export format
  export_type <- menu(
    c(
      "CSV",
      "XLSX"
    ),
    title = "Choose export format:"
  )
  
  if (export_type == 0) stop("No export file type selected.")
  
  if (!interactive()) {
    stop("Folder selection requires an interactive R session.")
  }
  
  # Ask user for export folder location
  get_export_folder <- function() {
    if (requireNamespace("rstudioapi", quietly = TRUE) &&
        rstudioapi::isAvailable()) {
      rstudioapi::selectDirectory()
    } else {
      choose.dir()
    }
  }
  message("Select folder only - DO NOT SPECIFY FILE NAME")
  export_folder <- get_export_folder()
  if (is.na(export_folder) || export_folder == "") {
    stop("No export folder selected.")
  }
  
  # Ask user for export file name
  export_file <- readline(
    prompt = "Enter file name (without extension): ")
  if (export_file == "") stop("No export file name provided.")
  
  # Add selected extension to the export file name
  export_ext <- ifelse(
    export_type == 1, 
    ".csv", 
    ".xlsx"
  )
  export_resPath <- file.path(
    export_folder,
    paste0(
      export_file,
      export_ext
    )
  )
  
  # Overwrite protection
  if (file.exists(export_resPath)) {
    overwrite <- menu(
      c(
        "Yes",
        "No"
      ),
      title = paste(
        "File already exists:\n",
        export_resPath,
        "\nOverwrite?"
      )
    )
    if (overwrite != 1) stop("Export cancelled by user.")
  }
  
  # Export file based on user choices
  if (export_type == 1) {
    write.csv(
      df,
      export_resPath,
      row.names = FALSE
    )
  } else {
    write.xlsx(
      df,
      export_resPath
    )
  }
  
  message("File saved to: ", export_resPath)
  
}