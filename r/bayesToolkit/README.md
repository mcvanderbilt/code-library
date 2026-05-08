# bayesToolkit

**bayesToolkit** is an R package providing a clean, accessible, and teaching‑focused implementation of Bayes’ Theorem with color‑blind‑safe visualizations. It is designed for instructional use in graduate‑level probability and statistics courses, including ANA500A.

The package includes:

- Robust input normalization for probabilities  
- A 3×3 contingency table generator  
- Posterior probability computation  
- Three Okabe–Ito color‑blind‑safe ggplot2 visualizations  
- Full roxygen2 documentation  

---

## Installation

You can install the package directly from GitHub:

```r
devtools::install_github(
  "mcvanderbilt/code-library",
  subdir = "r/bayesToolkit"
)
```

## Example
```r

library(bayesToolkit)

result <- bayes(7, 92, 7)

result$posterior_probability
result$contingency_table
result$barchart
result$heatmap
result$posterior_plot

```

## License
This package is licensed under the GNU Affero General Public License v3.0 (AGPL‑3).
See the LICENSE file for details.

## Author
**Matthew C. Vanderbilt, MSBA**