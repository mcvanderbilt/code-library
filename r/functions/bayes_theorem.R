# -------------------------------------------------------------------------
# Purpose: 
# Author: Matthew C. Vanderbilt, MSBA
# Created: 7 May 2026
# Updated: 7 May 2026
# -------------------------------------------------------------------------

bayes <- function(
      prevalence,                       # P(A)
      sensitivity,                      # P(B|A)
      false_positive,                   # P(B|A-)
      index = 1000,                     # N
      install_dependencies = TRUE
) {
  
  # LOAD NECESSARY LIBRARIES ------------------------------------------------
  loadLibrary <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      if (!install_dependencies) {
        stop(
          paste0(
            "The required package '",
            pkg, "' is not installed. ",
            "Set install_dependencies = TRUE to install it automatically."
          )
        )
      }
      install.packages(pkg)
    }
    suppressPackageStartupMessages(
      library(pkg,
              character.only = TRUE)
    )
  }
  
  loadLibrary("dplyr")
  loadLibrary("ggplot2")
  loadLibrary("tidyr")
  
  
  # PERCENTAGE CONVERSION HELPER --------------------------------------------
  pConvert <- function(x, name) {
    
    # Trim Whitespace with Character Entry
    if (is.character(x)) x <- trimws(x)
    
    # Remove Percent Sign if Entered
    if (is.character(x) && grepl("%$", x)) {
      x <- sub("%$", "", x)
    }
    
    # Check that Input is Numeric
    if (!is.numeric(x)) {
      x <- suppressWarnings(as.numeric(x))
      if (is.na(x)) stop(paste(name, "must be a numeric value or percentage"))
    }
    
    # Validate Input Range
    if (x < 0) stop(paste(name, "cannot be a negative value."))
    if (x > 100) stop(paste(name, "cannot exceed 1 or 100%."))
    
    # Convert Percent Input to Decimal
    if (x > 1) x <- x / 100
    
    # Return Acceptable Result
    return(x)
  }
  
  
  # VALIDATIONS & CONVERSIONS -----------------------------------------------

  # Validate & Convert Probability Inputs
  pA <- pConvert(prevalence, "Prevalence P(A)")
  pBgA <- pConvert(sensitivity, "Sensitivity P(B|A)")
  pBgAc <- pConvert(false_positive, "False Positive Rate P(B|A-)")
  
  # Validate Index Input
  if (!is.numeric(index) || index <= 0) {
    stop("Index must be a positive, numeric, value.")
  }
  
  
  # CALCULATE VALUES ------------------------------------------------------
  # Probability of Event A-
  pAc <- 1 - pA
  
  # Apply the Law of Total Probability
  pB <- (pBgA * pA) + (pBgAc * pAc)
  
  # Apply Bayes' Theorem
  pAgB <- (pBgA * pA) / pB
  
  # Recalculate Values to Index
  TP <- pBgA * pA * index
  FP <- pBgAc * pAc * index
  FN <- (1 - pBgA) * pA * index
  TN <- (1 - pBgAc) * pAc * index

  
  # GENERATE OUTPUT TABLE -------------------------------------------------  
  contingencyDF <- data.frame(
    Result = c(
      "Test Positive",
      "Test Negative",
      "Total"
    ),
    
    Condition_Positive = c(
      round(TP, 1),
      round(FN, 1),
      round(TP + FN, 1)
    ),
    
    Condition_Negative = c(
      round(FP, 1),
      round(TN, 1),
      round(FP + TN, 1)
    ),
    
    Total = c(
      round(TP + FP, 1),
      round(FN + TN, 1),
      round(index, 1)
    )
  )
  
  
  # GENERATE VISUALIZATIONS -----------------------------------------------
  # Prepare Data
  dfLong <- contingencyDF |>
    dplyr::filter(Result != "Total") |>
    tidyr::pivot_longer(
      cols = c(
        "Condition_Positive",
        "Condition_Negative"
      ),
      names_to = "Condition",
      values_to = "Count"
    )
  
  dfPost <- data.frame(
    label = "Posterior P(A|B)",
    value = pAgB
  )
  
  # Setup Okabe–Ito Palette for Accessibility
  okabe_ito <- c(
    "Condition_Positive" = "#0072B2", # Blue
    "Condition_Negative" = "#E69F00" # Orange
  )
  
  # Generate Grouped Bar Chart
  plotBarchart <- ggplot(
    dfLong,
    aes(
      x = Result,
      y = Count,
      fill = Condition
    )
  ) +
    geom_col(
      position = "dodge"
    ) +
    scale_fill_manual(
      values = okabe_ito
    ) +
    labs(
      title = "Bayes' Theorem Contingency Table",
      x = "Test Result",
      y = "Count"
    ) +
    theme_minimal(
      base_size = 14
    )
  
  # Generate Heatmap
  plotHeatmap <- ggplot(
    dfLong,
    aes(
      x = Condition,
      y = Result,
      fill = Count
    )
  ) +
    geom_tile(color = "white") +
    geom_text(
      aes(
        label = round(Count, 1)
      ),
      size = 5
    ) +
    scale_fill_gradient(
      low = "#56B4E9",   # Okabe-Ito Sky Blue
      high = okabe_ito["Condition_Positive"],  # Okabe-Ito Blue
    ) +
    labs(
      title = "Bayes' Theorem Heatmap",
      x = "Condition",
      y = "Test Result"
    ) +
    theme_minimal(
      base_size = 14
    )
  
  # Generate Posterior Probability Bar
  plotPosterior <- ggplot(
    dfPost,
    aes(
      x = label,
      y = value
    )
  ) +
    geom_col(fill = okabe_ito["Condition_Positive"]) +  # Okabe-Ito Blue
    geom_text(
      aes(
        label = paste0(
          round(value * 100, 1),
          "%"
        )
      ),
      vjust = -0.5,
      size = 6
    ) +
    ylim(0, 1) +
    labs(
      title = "Posterior Probability",
      x = "",
      y = "Probability"
    ) +
    theme_minimal(
      base_size = 14
    )

    
  # OUTPUT LIST -----------------------------------------------------------
  list(
    posterior_probability = round(pAgB, 4),
    contingency_table = contingencyDF,
    barchart = plotBarchart,
    heatmap = plotHeatmap,
    posterior_plot = plotPosterior
  )
  
}

calc <- bayes(.7, .93, .3)
calc$heatmap
calc$barchart
calc$posterior_plot
calc$contingency_table
View(calc$contingency_table)