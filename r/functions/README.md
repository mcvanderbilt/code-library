# Vanderbilt Code Library
**Matthew C. Vanderbilt, MSBA**

This directory contains **standalone, reusable R functions** such as those that support data
import, export, package loading, and workflow governance. These functions are not part of a
formal R package; instead, they serve as a **utility library** for analytics, teaching, and
internal BI workflows.

---

## Repository Structure
```
code-library/r/functions/
│
├── data-import-level-1.r     # Basic data import, lightweight and beginner-friendly helper
│
├── data-import-level-2.r     # Intermeidate data import; structured with additional checks
│
├── data-import-level-3.r     # Governed import workflow
│
├── export-data.r             # Flexible helper with CSV/XLSX, folder, and name guidance
│
└── load-packages.r           # Package loader with installation and duplicate avoidance
```

## Example Loading
See individual scripts for their use. The examples below show how to load them into your
project for use.
```r
source("https://raw.githubusercontent.com/mcvanderbilt/code-library/main/r/functions/export-data.r")
source("https://raw.githubusercontent.com/mcvanderbilt/code-library/main/r/functions/load-packages.r")
```

## License
All functions in this directory inherit the repository’s **GNU Affero General Public License
v3.0 (AGPL‑3)** in [LICENSE](LICENSE) unless otherwise specified.

## AI Notice
Some **documentation** has been generated or supplemented with the use of AI. Any other use is
specified in code comments.