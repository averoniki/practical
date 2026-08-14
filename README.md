# Practical — Setup and Run Instructions

This project uses `renv` to manage R package dependencies. Follow these steps to set up and run the project in RStudio.

## Prerequisites
- R (recommended: same major.minor recorded in `renv.lock`, e.g. 4.5.x)
- RStudio (optional but recommended)
- Git (to clone the repository)

## Quick start (recommended)
1. Clone the repository and change into the project directory:

```bash
git clone <repo-url>
cd Practical
```

2. Open R or RStudio in the project directory.

3. Install `renv` (if needed) and restore the project library from the lockfile:

```r
install.packages("renv")    # run once per machine
renv::restore()
```

4. Restart the R session (RStudio: Session -> Restart R) after `renv::restore()` completes.

```bash
Rscript DTA_Practical_v2.R
```

## Files to commit
- `renv.lock` — commit this file to version control (required).
- `renv/activate.R` and `.Rprofile` (if present) — commit if they were generated/modified.

Do NOT commit `renv/library/` (the per-project package cache) — add it to `.gitignore` if not already ignored.

## Troubleshooting

- If you see an error like `Error in sink(type = "output") : invalid connection` before running Stan, try the following in the R session to close stray sinks and inspect the error:

```r
# close any open output sinks
while (sink.number() > 0) sink(NULL)
# close any open message sinks
while (sink.number(type = "message") > 0) sink(NULL, type = "message")

# show the call stack after an error
traceback()

# restart R to ensure a clean session (recommended)
```

- If rstan complains about compilation or slow builds, ensure these options are set (they reduce recompilation and use multiple cores):

```r
options(mc.cores = parallel::detectCores())
rstan::rstan_options(auto_write = TRUE)
rstan::rstan_options(threads_per_chain = 1)
```

- If `renv::snapshot()` warns about missing packages, install those packages (or let `renv` install them during `renv::restore()`) before snapshotting again.

## Running on a different machine (summary)
1. Clone the repo.
2. In R: `install.packages("renv")` then `renv::restore()`.
3. Restart R.
4. Set the `rstan` options shown above and run `source("DTA_Practical_v2.R")` or `Rscript`.