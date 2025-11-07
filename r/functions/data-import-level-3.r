# -------------------------------------------------------------------------
# DATA SCIENCE STUDENT CHALLENGE: CREATION OF A CUSTOM FUNCTION (LEVEL 3)
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# FUNCTION: data.import()
# PURPOSE: Dynamic CSV/Excel file imports with descriptive statistics
# AUTHOR: Matthew C. Vanderbilt, MSBA
# CREATED: 7 November 2025
# UPDATED: 7 November 2025
# -------------------------------------------------------------------------
# AI-GENERATED DESCRIPTION:
# This function allows users to:
# - Select and import a CSV or Excel file via GUI file dialog
# - Automatically set the working directory to the file's location
# - Assign the imported data to a named object in the global environment
# - Identify all numeric (quantitative) variables
# - Dynamically select a variable for analysis (or analyze all variables)
# - Generate descriptive statistics using mosaic::favstats()
# - Format output and display using knitr::kable()
# - Classify distribution skewness (normal, positive, negative)
# - Display total record count
# - For single-variable analysis:
#     - Generate a histogram with density scaling
#     - Overlay a normal distribution curve
#     - Add vertical lines for mean and median
#     - Use theme_minimal(base_size = 14) for readability
# -------------------------------------------------------------------------
# ARGUMENTS:
# - table.name: Object name for imported data (default = "myData")
# - key.variable: Optional name of specific variable to analyze
# - dyn.select: If TRUE (default), allows dynamic selection from console
# -------------------------------------------------------------------------

data.import <- function(
  table.name = "myData",   # name of data object created by the function
  key.variable = NULL,     # optional variable name for focused analysis
  dyn.select = TRUE        # flag to enable dynamic variable selection
) {

  # Install required packages if not already available
  if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
  if (!requireNamespace("knitr", quietly = TRUE)) install.packages("knitr")
  if (!requireNamespace("mosaic", quietly = TRUE)) install.packages("mosaic")
  if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
  if (!requireNamespace("tools", quietly = TRUE)) install.packages("tools")

  # Load required packages
  library(ggplot2)    # data visualization
  library(knitr)      # formatted tables
  library(mosaic)     # descriptive statistics
  library(readxl)     # Excel file import
  library(tools)      # file type identification

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
      envir = .GlobalEnv # posts object to the global environment rather than only the local function
    )
  }, error = function(e) {
    message(paste("Failed to import file:", e$message))
    return(NULL)
  })

  # Define the table name for simplified internal coding
  df <- get(table.name)

  # Create internal function for calculation of descriptive statistics
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

    # Return formatted descriptive statistics as a data frame
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

  # Confirm existence of quantitative variable(s)
  df.vars <- names(df)[sapply(df, is.numeric)]
  if (length(df.vars) == 0) {
    message("No quantitative variables identified.")
    return(NULL)
  }

  # Allow dynamic variable selection if enabled by function call
  if (is.null(key.variable) && dyn.select) {
    key.variable <- select.list(
      df.vars,
      title = "Select a variable for analysis or type 0 for all variables.",
      multiple = FALSE,  # disables multi-selection
      graphics = FALSE   # disables graphical interface; uses console instead
    )
    if (key.variable == "") {
      key.variable <- NULL
    }
  }

  # Generated descriptive statistics and histogram for a single variable
  if (!is.null(key.variable)) {

    # Validate variable existence
    if (!key.variable %in% names(df)) {
      message("Identified variable not found in data frame.")
      return(NULL)
    }

    # Validate variable type as quantitative
    if (!is.numeric(df[[key.variable]])) {
      message("Quantitative variable not selected.")
      return(NULL)
    }

    # Generate descriptive statitsics using the internal function
    df.ds <- df.dsf(key.variable, df[[key.variable]])

    # Output a summary table to console
    print(
      kable(
        df.ds,
        digits = 2,
        align = kable.align,
        caption = paste("Descriptive Statistics for", key.variable)
      )
    )
    cat("\nTotal number of records in dataset:", formatC(nrow(df), format = "d", big.mark = ","), "\n")

    # Determine observations and statistics for the identified variable
    vector <- na.omit(df[[key.variable]])  # observed values without NAs
    x_bar <- mean(vector)                  # mean value of selected variabe
    x_squig <- median(vector)              # median value of selected variable  
    s <- sd(vector)                        # standard deviation of selected variable

    # Convert vector observations to a data frame for ggplot2
    df.hist.data <- data.frame(variable = vector)

    # Generate the frequency histogram with normal curve overlay
    df.hist <- ggplot(
      df.hist.data,
      aes(x = variable)
    ) +
      geom_histogram(
        aes(y = ..density..),
        fill = "steelblue",
        color = "black",
        alpha = .6
      ) +
      stat_function(
        fun = dnorm,
        args = list(
          mean = x_bar,
          sd = s
        ),
        color = "red",
        size = 1
      ) +
      geom_vline(
        xintercept = x_bar,
        color = "blue",
        size = 1
      ) +
      geom_vline(
        xintercept = x_squig,
        color = "blue",
        linetype = "dashed",
        size = 1
      ) +
      labs(
        title = paste("Frequency Histogram of", key.variable, "with Normal Curve Overlay"),
        x = key.variable,
        y = "Density"
      ) +
      theme_minimal(base_size = 14)

    # Output the histogram
    print(df.hist)

    # Enable loading of descriptive statistics through obj <- data.import(...)
    invisible(df.ds)

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

    # Loop through each quantitative variable to calculate descriptive statistics
    for (var in df.vars) {
      df.favstats <- rbind(
        df.favstats,
        df.dsf(var, df[[var]])
      )
    }

    # Output the summary table for all quantitative variables
    print(
      kable(
        df.favstats,
        digits = 2,
        align = kable.align,
        caption = "Descriptive Statistics for Quantitative Variables"
      )
    )

    # Write concluding notes bout ID number challenges and total record count
    cat("\nNote: Identification numbers may be misclassified as numeric variables. Please review manually.")
    cat("\nTotal number of records in dataset:", formatC(nrow(df), format = "d", big.mark = ","), "\n")

    # Enable loading of descriptive statistics through obj <- data.import(...)
    invisible(df.favstats)

  }
}