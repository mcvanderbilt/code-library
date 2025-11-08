# -------------------------------------------------------------------------
# DATA SCIENCE STUDENT CHALLENGE: CREATION OF A CUSTOM FUNCTION (LEVEL 2)
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# FUNCTION: data.import()
# PURPOSE:  Dynamic CSV/Excel file imports with descriptive statistics
# AUTHOR:   Matthew C. Vanderbilt, MSBA
# CREATED:  7 November 2025
# UPDATED:  7 November 2025
# -------------------------------------------------------------------------
# AI-GENERATED DESCRIPTION:
# This function allows users to:
# - Select and import a CSV or Excel file via GUI file dialogue
# - Automatically set the working directory to the file's location
# - Assign the imported data to a named object in the global environment
# - Identify all numeric (quantitative) variables in the dataset
# - Optionally specify a variable for focused analysis
# - Generate formatted descriptive statistics using mosaic::favstats()
# - Classify distribution skewness (normal, positive, negative)
# - Display results in a clean knitr::kable() table
# -------------------------------------------------------------------------
# ARGUMENTS:
# - table.name: Name to assign the imported data frame (default = "myData")
# - key.variable: Optional name of a numeric variable to summarize
# -------------------------------------------------------------------------


data.import <- function(table.name = "myData", key.variable = NULL) {

  # Install required packages if not already available
  if (!requireNamespace("knitr", quietly = TRUE)) install.packages("knitr")
  if (!requireNamespace("mosaic", quietly = TRUE)) install.packages("mosaic")
  if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
  if (!requireNamespace("tools", quietly = TRUE)) install.packages("tools")

  # Load required packages
  library(knitr)      # formatted tables
  library(mosaic)     # statistics functions
  library(readxl)     # reading from Excel
  library(tools)      # file type identification through filename parsing

  # Define text alignment for descriptive statistics output table
  kable.align <- c(
    "l", # left align the variable name
    "r", # right align the minimum
    "r", # right align the mean
    "r", # right align the median
    "r", # right align the standard deviation
    "r", # right align the maximum
    "r", # right algin missing value count
    "l"  # left align the skewness description
  )

  # Open file dialog fur user to dynamically select a file
  fileResolvedPath <- file.choose()

  # Set the working directory to the selected file's location
  tryCatch({
    setwd(dirname(fileResolvedPath))
  }, error = function(e) {
    message(paste("Failed to resolve directory: ", e$message))
    return(NULL)
  })

  # Utilize the tools package to identify the lowercase file type
  fileType <- tolower(file_ext(fileResolvedPath))

  # Import selected data from CSV or Excel files
  tryCatch({
    assign(
      table.name,
      if (fileType == "csv") {
        read.csv(fileResolvedPath, stringsAsFactors = FALSE)
      } else if (fileType %in% c("xls", "xlsx")) {
        read_excel(fileResolvedPath)
      } else {
        stop(paste("Unsupported file type:", fileType))
      },
      envir = .GlobalEnv
    )
  }, error = function(e) {
    message(paste("Failed to import file:", e$message))
    return(NULL)
  })

  # Define the table name for simplified internal coding
  df <- get(table.name)

  # Create descriptive statistics function with skewness identification
  df.dsf <- function(varname, vector) {
    df.stats <- favstats(vector)
    df.missing <- sum(is.na(vector))
    df.skew <- if (abs(df.stats$mean - df.stats$median) < .01 * df.stats$mean) {
      "Normally Distributed within 1%"
    } else if (df.stats$mean > df.stats$median) {
      "Distribution is Positively Skewed"
    } else if (df.stats$mean < df.stats$median) {
      "Distribution is Negatively Skewed"
    } else {
      "Unable to identify distribution skewness"
    }

    data.frame(
      Variable = varname,
      Min = formatC(
        df.stats$min,
        format = "f",
        digits = 2,
        big.mark = ","
      ),
      Mean = formatC(
        mean(vector, na.rm = TRUE),
        format = "f",
        digits = 2,
        big.mark = ","
      ),
      Median = formatC(
        df.stats$median,
        format = "f",
        digits = 2,
        big.mark = ","
      ),
      SD = formatC(
        sd(vector, na.rm = TRUE),
        format = "f",
        digits = 2,
        big.mark = ","
      ),
      Max = formatC(
        df.stats$max,
        format = "f",
        digits = 2,
        big.mark = ","
      ),
      Missing = formatC(
        df.missing,
        format = "d",
        big.mark = ","
      ),
      Skewness = df.skew,
      stringsAsFactors = FALSE
    )
  }

  # Calculate descriptive statistics and skewness
  if (!is.null(key.variable)) {

    if (!key.variable %in% names(df)) {
      message("Identified variable not found in data frame.")
      return(NULL)
    }

    if (!is.numeric(df[[key.variable]])) {
      message("Quantitative variable not selected.")
      return(NULL)
    }

    df.ds <- df.dsf(key.variable, df[[key.variable]])

    print(
      kable(
        df.ds,
        digits = 2,
        align = kable.align,
        caption = paste("Descriptive Statistics for", key.variable)
      )
    )
    cat("\nTotal number of records in dataset:", formatC(nrow(df), format = "d", big.mark = ","), "\n")
    invisible(df.ds) # returns a data frame allowing for data <- data.import(...) usage
  } else {
    df.vars <- names(df)[sapply(df, is.numeric)]
    if (length(df.vars) == 0) {
      message("No quantitative variables identified.")
      return(NULL)
    }

    # Initialize output variables
    df.favstats <- data.frame(
      Variable = character(),
      Min = numeric(),
      Mean = numeric(),
      Median = numeric(),
      SD = numeric(),
      Max = numeric(),
      Missing = integer(),
      Skewness = character(),
      stringsAsFactors = FALSE
    )

    for (var in df.vars) {
      df.favstats <- rbind(
        df.favstats,
        df.dsf(var, df[[var]])
      )
    }

    print(
      kable(
        df.favstats,
        digits = 2,
        align = kable.align,
        caption = "Descriptive Statistics for Quantitative Variables"
      )
    )

    cat("\nNote: Identification numbers may be misclassified as numeric variables. Please review manually.")
    cat("\nTotal number of records in dataset:", formatC(nrow(df), format = "d", big.mark = ","), "\n")

    invisible(df.favstats) # returns a data frame allowing for data <- data.import(...) usage

  }
}