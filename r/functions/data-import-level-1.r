# -------------------------------------------------------------------------
# DATA SCIENCE STUDENT CHALLENGE: CREATION OF A CUSTOM FUNCTION (LEVEL 1)
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# FUNCTION: data.import()
# PURPOSE:  CSV/Excel file imports with descriptive statistics
# AUTHOR:   Matthew C. Vanderbilt, MSBA
# CREATED:  7 November 2025
# UPDATED:  7 November 2025
# -------------------------------------------------------------------------
# AI-GENERATED DESCRIPTION:
# This function allows users to:
# - Specify a file path and name to import a CSV file
# - Automatically remove observations with missing values
# - Output the dataset to an object
# - Output descriptive statistics for a specified variable to console
# -------------------------------------------------------------------------
# ARGUMENTS:
# - filePath: Directory string to folder loation (not file name)
# - fileName: The name of a CSV file in filePath with file extension
# - key.variable: Name of a single numeric variable to analyze
# -------------------------------------------------------------------------
# WARNINGS:
# This function has no error handling and will fail at incorrect inputs
# Unless loaded to an object, the entire dataset will output to console
# -------------------------------------------------------------------------
# EXAMPLE USAGE:
myData <- data.import(
  filePath = "~/GitHub/NU-ANA605-Analytic-Models-Data-Systems/data/raw/",
  fileName = "dataset-dublin-listings.csv",
  key.variable = "bathrooms"
)
# -------------------------------------------------------------------------

data.import <- function(
  filePath,               # string specifying the complete file folder path
  fileName,               # string specifying the file name with extension
  key.variable            # string specifying the single variable to analyze
) {
    # Install and load the required package(s)
    if (!requireNamespace("mosaic", quietly = TRUE)) install.packages("mosaic")
    library(mosaic)       # statistics functions

    # Set the working directory to the specified file path
    setwd(filePath)
    message(paste("Working directory set to:", getwd()))

    # Import the CSV file into a data frame
    myData <- read.csv(fileName, stringsAsFactors = FALSE)
    message(
        paste(
            "File '",
            fileName,
            "' successfully imported with",
            nrow(myData),
            "observations."
        )
    )

    # Remove observations with missing values
    myData <- na.omit(myData)
    message(
        paste(
            "Successfully removed observations with missing values;",
            nrow(myData),
            "observations remain."
        )
    )

    # Check if the specified key variable exists in the data frame
    if (!(key.variable %in% names(myData))) {
        stop(
            paste(
                "The specified variable '",
                key.variable,
                "' was not found in the data frame."
            )
        )
    }

    # Output descriptive statistics to console
    message(
        paste(
            "Descriptive statistics for variable '",
            key.variable,
            "':"
        )
    )
    print(
        favstats(
            myData[[key.variable]]
        )
    )

    # Return the cleaned data frame for further analysis
    return(myData)

}



