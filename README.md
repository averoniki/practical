# Diagnostic Test Accuracy (DTA) Practical

A hands-on practical for learning Bayesian meta-analysis of diagnostic test accuracy using Stan.

## What This Project Does

This practical teaches you how to fit Bayesian models to diagnostic test accuracy data. The scripts will:
- Load and prepare diagnostic test data
- Fit a Bayesian hierarchical model using Stan
- Calculate sensitivity, specificity, and other diagnostic measures
- Create forest plots and league tables for comparing tests

## Getting Started

### Step 1: Install Prerequisites (First Time Only)

You need:
- **R** (version 4.5 or later) — download from [r-project.org](https://www.r-project.org/)
- **Compiler tools:**
  - **macOS:** Xcode Command Line Tools — open Terminal and run:
    ```bash
    xcode-select --install
    ```
  - **Windows:** Rtools 4.5 or later — download from [cran.r-project.org/bin/windows/Rtools](https://cran.r-project.org/bin/windows/Rtools/)

### Step 2: Clone the Repository

```bash
git clone https://github.com/averoniki/practical.git
```

```bash
cd Practical
```
### Step 3: Restore Project Packages

Open R or RStudio in the project directory and run:

```r
install.packages("renv")     # Install renv (first time only)
renv::restore()              # Restore all project packages
```

This downloads all the packages you need. It may take a few minutes.

After it finishes, restart R:
- **RStudio:** Session → Restart R
- **Terminal R:** exit and restart R

### Step 4: Run the Main Practical

In R, run:

```r
source("scripts/DTA_Practical_v2.R")
```

Or from Terminal:

```bash
Rscript scripts/DTA_Practical_v2.R
```

The script will:
1. Load the diagnostic test data
2. Compile the Bayesian model (takes ~1 minute)
3. Run the analysis (takes ~5 minutes)
4. Save results as CSV and Excel files to your project folder

**Output files:**
- `Results_date.csv` — summary statistics
- `Results_YYYY-MM-DD.xlsx` — Excel file with results
- `league_table_sens.xlsx` and `league_table_spec.xlsx` — comparison tables

## Project Structure

```
Practical/
├── README.md                    # This file
├── scripts/                     # R scripts to run
│   ├── DTA_Practical_v2.R      # Main practical (start here!)
│   └── [helper scripts]        # Functions for plots and tables
├── models/                      # Stan models
│   └── Nyaga_ANOVA.stan        # Bayesian diagnostic test accuracy model
├── data/                        # Input data files
│   └── 26045406.xlsx           # Example diagnostic test data
└── renv/                        # Package management (auto-generated)
```

## Troubleshooting

### Compiler tools not found (macOS/Windows)

**macOS:** You need Xcode Command Line Tools. Run in Terminal:
```bash
xcode-select --install
```

**Windows:** You need Rtools 4.5 or later. Download from [cran.r-project.org/bin/windows/Rtools](https://cran.r-project.org/bin/windows/Rtools/) and install it.

### "Could not find function 'cmdstan_model'"

This means cmdstanr didn't install. In R, run:
```r
renv::restore()
```

Then restart R.

### Model takes a very long time to compile

This is normal the first time. The Stan model is being compiled to C++. Subsequent runs are much faster.

### Results files don't appear

Check:
1. Is the script still running? (Look for messages in R console)
2. Do you have write permission in the project folder?
3. Look for error messages in red text — copy them to ask for help

## Running Other Scripts

The `scripts/` folder has helper scripts that create specific outputs:

- `mu_table.R` — creates sensitivity/specificity tables
- `league_table.R` — creates comparison league tables
- `describe_dta_network.R` — summarizes your data

These are automatically called by `DTA_Practical_v2.R`.

## Questions?

If something doesn't work:
1. **Copy the error message** (the red text in R)
2. **Note what step you were on**
3. Ask your instructor or check the troubleshooting section above

## For Instructors

To update dependencies after changing code:
```r
renv::snapshot()  # Updates renv.lock with current packages
```

Commit `renv.lock` to version control so students get the same packages.
