# Authors: Veroniki AA, Tsokani S
# Date: August 2026

#load functions required
source("scripts/describe_dta_network.R")
source("scripts/het_table.R")
source("scripts/dor_table.R")
source("scripts/league_table.R")
source("scripts/mu_table.R")

#install and setup rstan and packages needed
#install.packages("rstan", repos = "https://cloud.r-project.org/", dependencies = TRUE)

library(rstan)  # Load the rstan package for fitting Bayesian models with Stan
library(readxl) # Load the readxl package for importing Excel files
library(writexl)# Load the readxl package for exporting in Excel files

#setup rstan
options(mc.cores = parallel::detectCores()) # Allow Stan to use all available CPU cores to run chains in parallel
rstan_options(auto_write = TRUE) # Save compiled Stan models automatically to avoid recompiling them

# Import the "data" worksheet from the Excel file
dli<-read_excel("data/26045406.xlsx")
dli<-dli[1:15,1:8]
  
# Prepare the data in a list with the names expected by the Stan model
dat <- list(
  # Number of rows or observations in the dataset
  N = length(dli$study_id),
  
  # Number of unique diagnostic tests
  Nt = length(unique(dli$test_id)),
  
  # Number of unique studies
  Ns = length(unique(dli$study_id)),
  
  # Number of true-positive results
  TP = dli$tp,
  
  # Total number of diseased participants:
  # true positives plus false negatives
  Dis = dli$tp + dli$fn,
  
  # Number of true-negative results
  TN = dli$tn,
  
  # Total number of non-diseased participants:
  # false positives plus true negatives
  NDis = dli$fp + dli$tn,
  
  # Study identifier for each observation
  Study = dli$study_id,
  
  # Diagnostic test identifier for each observation
  Test = dli$test_id
)

# Descriptives of the network (requires the study and test identifiers mentioned as above)
describe_dta_network(dli) #where dli is the original dataset

# Make sure that Nyaga_ANOVA.stan is located in the models directory
# Fit the Bayesian diagnostic test accuracy model
fit_model <- stan(file = 'models/Nyaga_ANOVA.stan',
                 data = dat,   # Provide the data list prepared above
                 thin=10,      # Keep every 10th posterior draw to reduce the size of the saved output
                 warmup=100,   # Number of iterations discarded as warm-up
                 iter=2000,    # Total number of iterations per chain, including warm-up
                 chains=2)     # Number of independent Markov chains

# Extract the summary statistics from the fitted Stan model
model_summary <- summary(fit_model)

# Keep only the summary matrix containing parameter estimates,
# standard deviations, quantiles, and diagnostic statistics
gen_model_summary<-fit_model

# Convert the summary matrix into a data frame
df2 <- as.data.frame(model_summary)

# Add the parameter names as a separate column
df2$title <- rownames(df2)

# Export the model summary as a semicolon-separated CSV-style text file
write.table(
  df2,
  file = "G:/My Drive/Results_date.csv",
  sep = ";")

# Save in excel formatted file
writexl::write_xlsx(
  df2,
  path = paste0(
    "C:/Users/sofia/Dropbox/Argie_Course DTA/Results_",
    format(Sys.Date(), "%Y-%m-%d"),
    ".xlsx"
  )
)

# Save the complete fitted Stan model object for later use
# This allows you to reload the model without fitting it again
save(
  fit_model,
  file = paste0(
    "Results_model_",
    format(Sys.Date(), "%Y-%m-%d"),
    ".RData"
  )
)

# Results presentation and exploration ------------------------------------

# SENSITIVITY AND SPECIFICITY------------------------------------
#Have a look at sensitivity and specificity estimates
#mu_table function
results_table<-summary(
  fit_model,
  pars = c("MU"),
  probs = c(0.025, 0.5, 0.975)
)$summary

mu_table(results_table)


#HETEROGENEITY parameters------------------------------------
#het_table function
results_table_het<-summary(
  fit_model,
  pars = c("tausq","sigmabsq"),
  probs = c(0.025, 0.5, 0.975)
)$summary

results_table_het
het_table(results_table_het)

#DOR PARAMETER------------------------------------
#dor_table function
results_table_DOR<-summary(
  fit_model,
  pars = c("DOR"),
  probs = c(0.025, 0.5, 0.975)
)$summary

dor_table(results_table_DOR)

#Superiority index
Sk_index_table<-summary(
  fit_model,
  pars = c("S"),
  probs = c(0.025, 0.5, 0.975)
)$summary

Sk_index_table
#Create a LEAGUE TABLE------------------------------------
results_table_league<-summary(
  fit_model,
  pars = c("RD"), #relative ratio (sens_test2/sens_test1)
  probs = c(0.025, 0.5, 0.975)
)$summary

lt<-league_table_dta(dat,results_table_league)
View(lt$sensitivity$table)
View(lt$specificity$table)
writexl::write_xlsx(data.frame(lt$sensitivity$table),"league_table_sens.xlsx") #save league table for SENSITIVITY
writexl::write_xlsx(data.frame(lt$specificity$table),"league_table_spec.xlsx") #save league table for SPECIFICITY


# Assess convergence------------------------------------

# Examine trace plots for the main parameters
traceplot(fit_model, pars = c("MU"))
traceplot(fit_model, pars = c("sigmabsq"))
traceplot(fit_model, pars = c("tausq"))

# Display the distribution of Rhat values
stan_rhat(fit_model)

# Identify parameters with possible convergence problems
#diagnostics <- summary(fit_model)$summary
#diagnostics[diagnostics[, "Rhat"] > 1.01, "Rhat", drop = FALSE] # Check Parameters with Rhat greater than 1.01


#Results presentation------------------------------------
library(ggplot2)
results_table_df$outcome <- ifelse(
  grepl("^MU\\[1,", rownames(results_table_df)),
  "Sensitivity",
  ifelse(
    grepl("^MU\\[2,", rownames(results_table_df)),
    "Specificity",
    NA
  )
)

# Add a column with test number
results_table_df$test <- paste0(
  "Test ",
  sub("^MU\\[[12],([0-9]+)\\]$", "\\1", rownames(results_table_df))
)

#make the test factor, in order to appear sorted in the forest plot
results_table_df$test <- factor(
  results_table_df$test,
  levels = paste0("Test ", sort(unique(as.integer(sub("^MU\\[[12],([0-9]+)\\]$", "\\1", rownames(results_table_df))))))
)

#Create a forest plot
#Different plots
p <- ggplot(
  results_table_df,
  aes(
    y = test,
    x = `50%`,
    xmin = `2.5%`,
    xmax = `97.5%`,
    colour = outcome
  )
) +
  geom_pointrange() +
  facet_wrap(~ outcome, ncol = 1, scales = "free_y") +
  coord_cartesian(xlim = c(0, 1)) +
  labs(
    x = "Summary Estimate (95% Cr. Interval)",
    y = "Test Name"
  ) +
  theme(
    plot.title = element_text(size = 20, face = "bold"),
    axis.text.y = element_text(size=12),
    axis.ticks.y = element_blank(),
    axis.text.x = element_text(face = "bold"),
    axis.title = element_text(size = 15, face = "bold"),
    strip.text = element_text(face = "bold")
  )

p

#### Combined forest plot

dodge <- position_dodge(width = 0)

q <- ggplot(
  results_table_df,
  aes(
    y = test,
    x = `50%`,
    xmin = `2.5%`,
    xmax = `97.5%`,
    colour = outcome,
    group = outcome
  )
) +
  geom_errorbarh(position = dodge, height = 0.15, linewidth = 1) +
  geom_point(position = dodge, size = 3) +
  coord_cartesian(xlim = c(0, 1)) +
  labs(
    x = "Summary Estimate (95% CrI)",
    y = "Test Name",
    colour = "outcome"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.y = element_text(size = 12)
  )

q
