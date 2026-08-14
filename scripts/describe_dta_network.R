describe_dta_network <- function(df) {
  clean_df <- df %>%
    mutate(total_participants = tp + fn + tn + fp) %>%
    group_by(study_id) %>%
    slice_max(total_participants, n = 1, with_ties = FALSE) %>%
    ungroup()
  
  total_participants <- sum(clean_df$total_participants, na.rm = TRUE)
  total_tests <- n_distinct(df$test_id)
  
  study_geometry <- df %>%
    count(study_id, name = "n_tests") %>%
    mutate(
      n_comparisons = n_tests * (n_tests - 1) / 2,
      category = case_when(
        n_tests == 1 ~ "Single-test studies",
        n_tests == 2 ~ "Studies comparing 2 tests",
        n_tests >= 3 ~ "Studies comparing 3 or more tests"
      )
    )
  
  geometry_summary <- study_geometry %>%
    group_by(category) %>%
    summarise(
      n_studies = n(),
      total_comparisons = sum(n_comparisons, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    bind_rows(
      tibble(
        category = "Total",
        n_studies = sum(.$n_studies, na.rm = TRUE),
        total_comparisons = sum(.$total_comparisons, na.rm = TRUE)
      )
    )
  
  list(
    total_participants = total_participants,
    total_tests = total_tests,
    geometry_summary = geometry_summary
  )
}