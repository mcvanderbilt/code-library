# Vanderbilt Code Library
**Matthew C. Vanderbilt, MSBA**

This repository is a multi‑language **code library monorepo** containing reusable tools, teaching materials, and utilities across R, Python, SQL, and other technologies. It is designed to support analytics, data science instruction, reproducible research, and operational workflows.

**NOTE:** Migration to GitHub in progress.

---

## Repository Structure
```
code-library/
│
├── code-library.Rproj        # Single RStudio project for the entire monorepo
|
├── data/                     # Generated, sample, and reference datasets
│
├── docs/                     # Documentation and teaching materials
│
├── python/                   # Python modules and utilities
│
├── r/                        # All R packages live here
│   ├── bayesToolkit/         # Bayes' Theorem teaching package
|   ├── functions/            # Miscellaneous reusable functions and code snippets
|   ├── objects/              # Deprecating
│   └── ...
│
├── scripts/                  # Executable scripts and automatio
│
├── sql/                      # SQL scripts and transformations
│
└── scripts/                  # Executable scripts and automation
```

## License
This repository contains a primary [LICENSE](LICENSE), while individual components may be provided under different license. See subfolder LICENSE and DESCRIPTION files for details. Where not otherwise provided, the primary LICENSE applies.