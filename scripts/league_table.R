league_table_dta <- function(dat, results_table_league) {
  n <- dat$Nt
  results_table_league <- as.data.frame(results_table_league)

  make_table <- function(k, outcome_name) {
    league <- matrix(NA_character_, nrow = n, ncol = n)

    for (i in 1:n) {
      for (j in 1:n) {
        if (i == j) {
          league[i, j] <- "—"
        } else {
          p <- paste0("RD[", k, ",", i, ",", j, "]")
          row <- results_table_league[results_table_league$variable == p, ]
          if (nrow(row) == 1) {
            league[i, j] <- sprintf(
              "%.2f (%.2f, %.2f)",
              row[["50%"]],
              row[["2.5%"]],
              row[["97.5%"]]
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
