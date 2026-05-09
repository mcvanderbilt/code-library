# Introduction to bayesToolkit

``` r

library(bayesToolkit)
```

## Overview

`bayesToolkit` provides an implementation of Bayes’ Theorem, including:

- input normalization for prevalence, sensitivity, and false positive
  rates  
- a scaled contingency table  
- three color-impaired-safe visualizations  
- a clean, reproducible workflow

## Basic Example

``` r

library(bayesToolkit)

result <- bayes(7, 92, 7)

result$posterior_probability
result$contingency_table
result$barchart
result$heatmap
result$posterior_plot
```

## Input Formats

The function accepts multiple numeric formats with all inputs validated
and converted to decimal probabilities.

- decimals(.07)
- whole numbers (7)
- percentage strings (“7%”)

## Visualizations

The function returns three ggplot2 objects using the Okabe-Ito palette
for accessibility:

- grouped barchart
- heatmap
- posterior probability bar plot

## Output Structure

The function returns a list:

``` r

str(result)
```

## Conclusion

`bayesToolkit` is designed for clarity, reproducibility, and
accessibility in probability and statistics calculations.
