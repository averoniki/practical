league_table_dta <- function(dat, results_table_league) {
  n <- dat$Nt
  
  make_table <- function(k, outcome_name) {
    league <- matrix(NA_character_, nrow = n, ncol = n)
    
    for (i in 1:n) {
      for (j in 1:n) {
        if (i == j) {
          league[i, j] <- "—"
        } else {
          p <- paste0("RD[", k, ",", i, ",", j, "]")
          if (p %in% rownames(results_table_league)) {
            league[i, j] <- sprintf(
              "%.2f (%.2f, %.2f)",
              results_table_league[p, "50%"],
              results_table_league[p, "2.5%"],
              results_table_league[p, "97.5%"]
            )
          }
        }
      }
    }
    
    rownames(league) <- paste0("Test ", 1:n)
    colnames(league) <- paste0("Test ", 1:n)
    
    list(
      outcome = outcome_name,
      table = league
    )
  }
  
  list(
    sensitivity = make_table(1, "Sensitivity"),
    specificity = make_table(2, "Specificity")
  )
}
