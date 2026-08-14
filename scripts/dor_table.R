library(dplyr)
library(tibble)

dor_table<-function(results_table_DOR){
dor_table <- as.data.frame(results_table_DOR) %>%
  rownames_to_column("Test") %>%
  mutate(
    DOR = sprintf("%.3f (%.3f, %.3f)", `50%`, `2.5%`, `97.5%`)
  ) %>%
  select(Test, DOR)

  return(dor_table)}
