##Network Plot

library(dplyr)
library(tidyr)
library(igraph)

plot_dta_network <- function(df) {
  
  tests_by_study <- df %>%
    distinct(study_id, test_id) %>%
    group_by(study_id) %>%
    summarise(
      n_tests = n_distinct(test_id),
      tests = list(sort(unique(as.character(test_id)))),
      .groups = "drop"
    )
  
  nodes <- df %>%
    distinct(test_id) %>%
    transmute(name = as.character(test_id))
  
  edges <- tests_by_study %>%
    filter(n_tests >= 2) %>%
    rowwise() %>%
    mutate(
      edge_df = list({
        m <- combn(tests, 2)
        tibble(
          from = m[1, ],
          to = m[2, ],
          edge_type = if_else(n_tests == 2, "solid", "dashed"),
          lty = if_else(n_tests == 2, 1, 2)
        )
      })
    ) %>%
    ungroup() %>%
    select(edge_df) %>%
    unnest(edge_df)
  
  g <- graph_from_data_frame(edges, vertices = nodes, directed = FALSE)
  
  E(g)$lty <- ifelse(E(g)$edge_type == "solid", 1, 2)
  
  plot(
    g,
    layout = layout_with_fr(g),
    vertex.size = 26,
    vertex.color = "lightblue",
    vertex.frame.color = "black",
    vertex.label.color = "black",
    vertex.label.cex = 0.8,
    edge.color = "grey40",
    edge.width = 1.5,
    edge.lty = E(g)$lty,
    edge.curved = ifelse(which_multiple(g), 0.2, 0)
  )
}


# Plot function 2

plot_dta_network <- function(df) {
  
  tests_by_study <- df %>%
    distinct(study_id, test_id) %>%
    group_by(study_id) %>%
    summarise(
      n_tests = n_distinct(test_id),
      tests = list(sort(unique(as.character(test_id)))),
      .groups = "drop"
    )
  
  single_counts <- tests_by_study %>%
    filter(n_tests == 1) %>%
    transmute(test_id = unlist(tests)) %>%
    count(test_id, name = "single_study_count")
  
  nodes <- df %>%
    distinct(test_id) %>%
    mutate(test_id = as.character(test_id)) %>%
    left_join(single_counts, by = "test_id") %>%
    mutate(
      single_study_count = ifelse(is.na(single_study_count), 0L, single_study_count),
      name = test_id,
      label = paste0(test_id, " (", single_study_count, ")")
    ) %>%
    select(name, label, single_study_count)
  
  edges <- tests_by_study %>%
    filter(n_tests >= 2) %>%
    rowwise() %>%
    mutate(
      edge_df = list({
        m <- combn(tests, 2)
        tibble(
          from = m[1, ],
          to = m[2, ],
          edge_type = if_else(n_tests == 2, "solid", "dashed")
        )
      })
    ) %>%
    ungroup() %>%
    select(edge_df) %>%
    unnest(edge_df) %>%
    count(from, to, edge_type, name = "n_studies") %>%
    mutate(
      lty = if_else(edge_type == "solid", 1, 2),
      edge_label = as.character(n_studies)
    )
  
  g <- graph_from_data_frame(edges, vertices = nodes, directed = FALSE)
  
  plot(
    g,
    layout = layout_with_fr(g),
    vertex.size = 26,
    vertex.color = "lightgreen",
    vertex.frame.color = "black",
    vertex.label = V(g)$label,
    vertex.label.color = "black",
    vertex.label.cex = 0.8,
    edge.color = "grey40",
    edge.width = 1.5,
    edge.lty = E(g)$lty,
    edge.label = E(g)$edge_label,
    edge.label.cex = 0.8,
    edge.label.color = "black",
    edge.curved = ifelse(which_multiple(g), 0.2, 0)
  )
}

##Option 3

plot_dta_network <- function(df) {
  
  tests_by_study <- df %>%
    distinct(study_id, test_id) %>%
    group_by(study_id) %>%
    summarise(
      n_tests = n_distinct(test_id),
      tests = list(sort(unique(as.character(test_id)))),
      .groups = "drop"
    )
  
  single_counts <- tests_by_study %>%
    filter(n_tests == 1) %>%
    transmute(test_id = unlist(tests)) %>%
    count(test_id, name = "single_study_count")
  
  nodes <- df %>%
    distinct(test_id) %>%
    mutate(test_id = as.character(test_id)) %>%
    left_join(single_counts, by = "test_id") %>%
    mutate(
      single_study_count = replace_na(single_study_count, 0L),
      label = paste0(test_id, " (", single_study_count, ")")
    ) %>%
    select(name = test_id, label, single_study_count)
  
  edges <- tests_by_study %>%
    filter(n_tests >= 2) %>%
    rowwise() %>%
    mutate(edge_df = list({
      m <- combn(tests, 2)
      tibble(
        from = m[1, ],
        to = m[2, ],
        edge_type = if_else(n_tests == 2, "solid", "dashed")
      )
    })) %>%
    ungroup() %>%
    select(edge_df) %>%
    unnest(edge_df) %>%
    count(from, to, edge_type, name = "n_studies") %>%
    mutate(
      lty = if_else(edge_type == "solid", "solid", "dashed")
    )
  
  graph <- tbl_graph(nodes = nodes, edges = edges, directed = FALSE)
  
  ggraph(graph, layout = "fr") +
    geom_edge_link(aes(linetype = lty, alpha = n_studies),
                   colour = "grey45",
                   lineend = "round",
                   show.legend = FALSE) +
    geom_node_point(aes(size = single_study_count),
                    colour = "green",
                    fill = "lightgreen",
                    shape = 21,
                    stroke = 0.4) +
    geom_node_text(aes(label = label), size = 3, repel = TRUE) +
    scale_edge_linetype_identity() +
    scale_edge_alpha(range = c(0.4, 1)) +
    scale_size(range = c(4, 8), guide = "none") +
    theme_void()
}