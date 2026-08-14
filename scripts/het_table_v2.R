het_table_v2 <- function(results_table_het) {
  as.data.frame(results_table_het) %>%
    tibble::rownames_to_column("Parameter") %>%
    mutate(
      idx1 = stringr::str_match(Parameter, "^(tausq|sigmabsq)\\[(\\d+)(?:,(\\d+))?\\]$")[, 3],
      idx2 = stringr::str_match(Parameter, "^(tausq|sigmabsq)\\[(\\d+)(?:,(\\d+))?\\]$")[, 4],
      Outcome = dplyr::case_when(
        idx1 == "1" ~ "Sensitivity",
        idx1 == "2" ~ "Specificity",
        TRUE ~ NA_character_
      ),
      Test = dplyr::case_when(
        grepl("^tausq", Parameter) ~ paste0("Test ", idx2),
        grepl("^sigmabsq", Parameter) ~ Outcome
      ),
      Estimate = sprintf("%.3f (%.3f, %.3f)", `50%`, `2.5%`, `97.5%`)
    ) %>%
    select(Test, Outcome, Estimate)
}

