#!/usr/bin/env Rscript
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("cmdstanr", quietly = TRUE)) {
  libs <- .libPaths()
  writable <- Filter(function(p) file.access(p, 2) == 0, libs)
  if (length(writable) == 0) {
    userlib <- file.path(Sys.getenv("HOME"), "R", paste0("library-", R.version$major, ".", R.version$minor))
    dir.create(userlib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(userlib, .libPaths()))
    writable <- userlib
  } else {
    writable <- writable[[1]]
  }
  install.packages("cmdstanr", lib = writable, repos = "https://cloud.r-project.org")
}
library(cmdstanr)
if (is.null(cmdstanr::cmdstan_version())) {
  message("Cmdstan not found — installing (this may take many minutes)...")
  cmdstanr::install_cmdstan()
}
library(readxl)

# load data (same subset as the original script)
dli <- read_excel("data/26045406.xlsx")
dli <- dli[1:15, 1:8]

dat <- list(
  N = length(dli$study_id),
  Nt = length(unique(dli$test_id)),
  Ns = length(unique(dli$study_id)),
  TP = dli$tp,
  Dis = dli$tp + dli$fn,
  TN = dli$tn,
  NDis = dli$fp + dli$tn,
  Study = dli$study_id,
  Test = dli$test_id
)

stan_file <- "models/Nyaga_ANOVA.stan"
if (!file.exists(stan_file)) stop("Stan file not found: ", stan_file)

mod <- cmdstan_model(stan_file)

message("Sampling with cmdstanr...")
fit <- mod$sample(data = dat,
                  chains = 2,
                  parallel_chains = 2,
                  iter_warmup = 100,
                  iter_sampling = 1900,
                  thin = 10)

message("Saving results...")
write.csv(fit$summary(), file = "cmdstanr_model_summary.csv", row.names = FALSE)
saveRDS(fit, file = "cmdstanr_fit.rds")
message("Done. Summary saved to cmdstanr_model_summary.csv")
