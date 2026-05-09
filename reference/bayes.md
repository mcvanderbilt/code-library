# Bayes' Theorem Calculator with Color‑Impaired‑Safe Visualizations Computes the posterior probability \\P(A\|B)\\ using Bayes' Theorem, generates a contingency table scaled to a user‑defined population size, and produces three color‑blind‑safe ggplot2 visualizations: a grouped bar chart, a heatmap, and a posterior probability bar plot.

This function accepts prevalence, sensitivity, and false positive rate
as decimals, whole numbers, or percentage strings (e.g., `"7%"`, `"92"`,
`"0.07"`). All inputs are validated and normalized to decimal
probabilities.

## Usage

``` r
bayes(
  prevalence,
  sensitivity,
  false_positive,
  index = 1000,
  install_dependencies = TRUE
)
```

## Arguments

- prevalence:

  Prevalence \\P(A)\\. Accepts numeric values or percentage strings.

- sensitivity:

  Sensitivity \\P(B\|A)\\. Accepts numeric values or percentage strings.

- false_positive:

  False positive rate \\P(B\|A^-)\\. Accepts numeric values or
  percentage strings.

- index:

  Population size used to scale the contingency table (default = 1000).

- install_dependencies:

  Logical. If `TRUE`, missing packages (`dplyr`, `ggplot2`, `tidyr`) are
  installed automatically. If `FALSE`, the function stops with an
  informative error when a required package is not installed.

## Value

A named list containing:

- posterior_probability:

  Posterior probability \\P(A\|B)\\ rounded to four decimals.

- contingency_table:

  A 3×3 data frame of scaled counts.

- barchart:

  Grouped bar chart of test results by condition (ggplot2 object).

- heatmap:

  Heatmap of the contingency table (ggplot2 object).

- posterior_plot:

  Posterior probability bar plot (ggplot2 object).

## Details

The function performs the following steps:

1.  Validates and converts all probability inputs to decimals.

2.  Computes \\P(B)\\ using the Law of Total Probability

3.  Computes posterior probability using Bayes' Theorem.

4.  Constructs a 3×3 contingency table with:

    - True Positives (TP)

    - False Positives (FP)

    - False Negatives (FN)

    - True Negatives (TN)

5.  Generates three color‑blind‑safe ggplot2 visualizations using the
    Okabe–Ito palette.

## Examples

``` r
# Basic usage
bayes(7, 92, 7)
#> $posterior_probability
#> [1] 0.4973
#> 
#> $contingency_table
#>          Result Condition_Positive Condition_Negative  Total
#> 1 Test Positive               64.4               65.1  129.5
#> 2 Test Negative                5.6              864.9  870.5
#> 3         Total               70.0              930.0 1000.0
#> 
#> $barchart

#> 
#> $heatmap

#> 
#> $posterior_plot

#> 

# Using decimal inputs
bayes(0.07, 0.92, 0.07)
#> $posterior_probability
#> [1] 0.4973
#> 
#> $contingency_table
#>          Result Condition_Positive Condition_Negative  Total
#> 1 Test Positive               64.4               65.1  129.5
#> 2 Test Negative                5.6              864.9  870.5
#> 3         Total               70.0              930.0 1000.0
#> 
#> $barchart

#> 
#> $heatmap

#> 
#> $posterior_plot

#> 

# Without automatic package installation
if (FALSE) { # \dontrun{
bayes(7, 92, 7, install_dependencies = FALSE)
} # }
```
