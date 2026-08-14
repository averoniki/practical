het_table <- function(results_table_het) {
  het_table<-as.data.frame(results_table_het) %>%
    tibble::rownames_to_column("Test") %>%
    mutate(
      Estimate = sprintf("%.3f (%.3f, %.3f)", `50%`, `2.5%`, `97.5%`)
    ) %>%
    select(Test, Estimate)
  return(het_table)
}

