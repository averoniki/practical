mu_table <- function(results_table_df) {
  as.data.frame(results_table_df) %>%
    tibble::rownames_to_column("Parameter") %>%
    mutate(
      Outcome = dplyr::case_when(
        grepl("^MU\\[1,", Parameter) ~ "Sensitivity",
        grepl("^MU\\[2,", Parameter) ~ "Specificity",
        TRUE ~ NA_character_
      ),
      Test = paste0("Test ", sub("^MU\\[(1|2),", "", sub("\\]$", "", Parameter))),
      Estimate = sprintf("%.3f (%.3f, %.3f)", `50%`, `2.5%`, `97.5%`)
    ) %>%
    select(Test, Outcome, Estimate)
}

#mu_table(results_table_df)
