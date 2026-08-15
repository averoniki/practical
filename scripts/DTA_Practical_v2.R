# Authors: Veroniki AA, Tsokani S
# Date: August 2026

#load functions required
source("scripts/describe_dta_network.R")
source("scripts/het_table.R")
source("scripts/dor_table.R")
source("scripts/league_table.R")
source("scripts/mu_table.R")

library(cmdstanr)  # Load the cmdstanr package for fitting Bayesian models with Stan
library(readxl)    # Load the readxl package for importing Excel files
library(writexl)   # Load the writexl package for exporting in Excel files

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
model <- cmdstan_model('models/Nyaga_ANOVA.stan')
fit_model <- model$sample(
  data = dat,
  thin = 10,
  iter_warmup = 100,
  iter_sampling = 1900,
  chains = 2
)

# Extract the summary statistics from the fitted Stan model
model_summary <- fit_model$summary()

# Keep only the summary matrix containing parameter estimates,
# standard deviations, quantiles, and diagnostic statistics
gen_model_summary<-fit_model

# Convert the summary matrix into a data frame
df2 <- as.data.frame(model_summary)

# Add the parameter names as a separate column
df2$title <- df2$variable

# Export the model summary as a comma-separated CSV file
write.csv(
  df2,
  file = paste0(
    "Results_",
    format(Sys.Date(), "%Y-%m-%d"),
    ".csv"
  ),
  row.names = FALSE
)

# Save in excel formatted file
writexl::write_xlsx(
  df2,
  path = paste0(
    "Results_",
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
results_table <- fit_model$summary(
  variables = c("MU"),
  "mean", "median", "sd", "mad",
  ~quantile(.x, probs = c(0.025, 0.5, 0.975)),
  "rhat", "ess_bulk", "ess_tail"
)

mu_table(results_table)


#HETEROGENEITY parameters------------------------------------
#het_table function
results_table_het <- fit_model$summary(
  variables = c("tausq","sigmabsq"),
  "mean", "median", "sd", "mad",
  ~quantile(.x, probs = c(0.025, 0.5, 0.975)),
  "rhat", "ess_bulk", "ess_tail"
)

results_table_het
het_table(results_table_het)

#DOR PARAMETER------------------------------------
#dor_table function
results_table_DOR <- fit_model$summary(
  variables = c("DOR"),
  "mean", "median", "sd", "mad",
  ~quantile(.x, probs = c(0.025, 0.5, 0.975)),
  "rhat", "ess_bulk", "ess_tail"
)

dor_table(results_table_DOR)

#Superiority index
Sk_index_table <- fit_model$summary(
  variables = c("S"),
  "mean", "median", "sd", "mad",
  ~quantile(.x, probs = c(0.025, 0.5, 0.975)),
  "rhat", "ess_bulk", "ess_tail"
)

Sk_index_table
#Create a LEAGUE TABLE------------------------------------
results_table_league <- fit_model$summary(
  variables = c("RD"), #relative ratio (sens_test2/sens_test1)
  "mean", "median", "sd", "mad",
  ~quantile(.x, probs = c(0.025, 0.5, 0.975)),
  "rhat", "ess_bulk", "ess_tail"
)

lt<-league_table_dta(dat,results_table_league)
View(lt$sensitivity$table)
View(lt$specificity$table)
writexl::write_xlsx(data.frame(lt$sensitivity$table),"league_table_sens.xlsx") #save league table for SENSITIVITY
writexl::write_xlsx(data.frame(lt$specificity$table),"league_table_spec.xlsx") #save league table for SPECIFICITY


# Assess convergence------------------------------------

# Examine trace plots for the main parameters
fit_model$draws(variables = c("MU")) |> bayesplot::mcmc_trace()
fit_model$draws(variables = c("sigmabsq")) |> bayesplot::mcmc_trace()
fit_model$draws(variables = c("tausq")) |> bayesplot::mcmc_trace()

# Display convergence diagnostics
fit_model$cmdstan_diagnose()

# Identify parameters with possible convergence problems
#diagnostics <- summary(fit_model)$summary
#diagnostics[diagnostics[, "Rhat"] > 1.01, "Rhat", drop = FALSE] # Check Parameters with Rhat greater than 1.01


#Results presentation------------------------------------
library(ggplot2)
results_table_df <- as.data.frame(results_table)

results_table_df$outcome <- ifelse(
  grepl("^MU\\[1,", results_table_df$variable),
  "Sensitivity",
  ifelse(
    grepl("^MU\\[2,", results_table_df$variable),
    "Specificity",
    NA
  )
)

# Add a column with test number
results_table_df$test <- paste0(
  "Test ",
  sub("^MU\\[[12],([0-9]+)\\]$", "\\1", results_table_df$variable)
)

#make the test factor, in order to appear sorted in the forest plot
results_table_df$test <- factor(
  results_table_df$test,
  levels = paste0("Test ", sort(unique(as.integer(sub("^MU\\[[12],([0-9]+)\\]$", "\\1", results_table_df$variable)))))
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

dodge <- position_dodge(width = 0.5)

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
  geom_errorbar(position = dodge, width = 0.15, orientation = "y", linewidth = 1) +
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

