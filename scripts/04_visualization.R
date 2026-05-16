source("_init.R")
library(tidyverse)
library(corrplot)

df <- read_csv("data/processed/feeding_trials_clean.csv", show_col_types = FALSE)

theme_mars <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )

formula_colors <- c("Control" = "#D4A373", "New Protein" = "#BC6C25",
                    "New Flavour Coating" = "#606C38")

species_shapes <- c("Dog" = 16, "Cat" = 17)

cat("Generating plots...\n\n")

tukey_pairs <- TukeyHSD(aov(palatability_score ~ formula_label, data = df))

tukey_df <- as.data.frame(tukey_pairs$formula_label) %>%
  rownames_to_column("comparison") %>%
  as_tibble() %>%
  filter(`p adj` < 0.05)

y_max <- max(df$palatability_score, na.rm = TRUE)
bracket_y <- y_max + seq(0.2, by = 0.4, length.out = nrow(tukey_df))

p1 <- ggplot(df, aes(x = formula_label, y = palatability_score,
                      fill = formula_label)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.15, alpha = 0.15, size = 1) +
  scale_fill_manual(values = formula_colors, guide = "none") +
  labs(
    title = "Palatability Score by Food Formula",
    subtitle = "2x3 factorial feeding trial | Box plots with individual observations",
    x = "Food Formula",
    y = "Palatability Score (1-10)"
  ) +
  theme_mars +
  coord_cartesian(ylim = c(0, max(bracket_y) + 0.5))

if (nrow(tukey_df) > 0) {
  for (i in seq_len(nrow(tukey_df))) {
    labs_vec <- strsplit(tukey_df$comparison[i], "-")[[1]]
    x1 <- which(levels(df$formula_label) %in% trimws(labs_vec[1]))
    x2 <- which(levels(df$formula_label) %in% trimws(labs_vec[2]))
    p1 <- p1 +
      annotate("segment", x = x1, xend = x2,
               y = bracket_y[i], yend = bracket_y[i]) +
      annotate("segment", x = x1, xend = x1,
               y = bracket_y[i] - 0.15, yend = bracket_y[i]) +
      annotate("segment", x = x2, xend = x2,
               y = bracket_y[i] - 0.15, yend = bracket_y[i]) +
      annotate("text", x = (x1 + x2) / 2, y = bracket_y[i] + 0.15,
               label = paste0("p=", sprintf("%.3f", tukey_df$`p adj`[i])),
               size = 3)
  }
}

ggsave("plots/palatability_by_formula.png", p1, width = 8, height = 6, dpi = 300)
cat("1. palatability_by_formula.png saved\n")

summary_data <- df %>%
  group_by(species, formula_label) %>%
  summarise(
    mean_score = mean(palatability_score, na.rm = TRUE),
    se = sd(palatability_score, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

p2 <- ggplot(summary_data, aes(x = formula_label, y = mean_score,
                               fill = species)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
  geom_errorbar(aes(ymin = mean_score - se, ymax = mean_score + se),
                position = position_dodge(width = 0.7), width = 0.2) +
  scale_fill_manual(values = c("Dog" = "#9B5DE5", "Cat" = "#F15BB5"),
                    name = "Species") +
  labs(
    title = "Mean Palatability Score by Species and Formula",
    subtitle = "Error bars represent standard error of the mean",
    x = "Food Formula",
    y = "Mean Palatability Score"
  ) +
  theme_mars

ggsave("plots/species_comparison.png", p2, width = 8, height = 6, dpi = 300)
cat("2. species_comparison.png saved\n")

interaction_data <- df %>%
  group_by(species, formula_label) %>%
  summarise(
    mean_score = mean(palatability_score, na.rm = TRUE),
    se = sd(palatability_score, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

p3 <- ggplot(interaction_data, aes(x = formula_label, y = mean_score,
                                   color = species, group = species)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 4) +
  geom_ribbon(aes(ymin = mean_score - se, ymax = mean_score + se,
                  fill = species), alpha = 0.15, color = NA) +
  scale_color_manual(values = c("Dog" = "#9B5DE5", "Cat" = "#F15BB5"),
                     name = "Species") +
  scale_fill_manual(values = c("Dog" = "#9B5DE5", "Cat" = "#F15BB5"),
                    guide = "none") +
  labs(
    title = "Interaction Plot: Formula x Species",
    subtitle = "Parallel lines suggest no interaction; crossing lines suggest interaction",
    x = "Food Formula",
    y = "Mean Palatability Score"
  ) +
  theme_mars

ggsave("plots/interaction_plot.png", p3, width = 8, height = 6, dpi = 300)
cat("3. interaction_plot.png saved\n")

numeric_vars <- df %>%
  select(
    `Palatability\nScore` = palatability_score,
    `Time to\nFirst Bite` = time_to_first_bite,
    `Consumed\nAmount (g)` = consumed_amount_grams,
    `Age\n(months)` = age_months,
    `Weight\n(kg)` = weight_kg
  ) %>%
  drop_na()

cor_mat <- cor(numeric_vars)

png("plots/correlation_heatmap.png", width = 800, height = 700, res = 150)
corrplot(cor_mat,
         method = "color",
         type = "lower",
         addCoef.col = "black",
         tl.col = "black",
         tl.srt = 45,
         tl.cex = 0.8,
         number.cex = 0.8,
         col = colorRampPalette(c("#BC6C25", "white", "#606C38"))(200),
         title = "Correlation Matrix: Numeric Variables",
         mar = c(0, 0, 2, 0))
dev.off()

cat("4. correlation_heatmap.png saved\n")

p5 <- ggplot(df, aes(x = formula_label, y = palatability_score,
                     fill = species)) +
  geom_violin(alpha = 0.6, position = position_dodge(width = 0.8),
              quantiles = c(0.25, 0.5, 0.75)) +
  geom_jitter(aes(color = species), position = position_jitterdodge(jitter.width = 0.1),
              alpha = 0.2, size = 0.8, show.legend = FALSE) +
  scale_fill_manual(values = c("Dog" = "#9B5DE5", "Cat" = "#F15BB5"),
                    name = "Species") +
  scale_color_manual(values = c("Dog" = "#9B5DE5", "Cat" = "#F15BB5")) +
  labs(
    title = "Palatability Score Distribution by Formula and Species",
    subtitle = "Violin plots with quartile lines and individual observations",
    x = "Food Formula",
    y = "Palatability Score (1-10)"
  ) +
  theme_mars

ggsave("plots/violin_plot.png", p5, width = 9, height = 6, dpi = 300)
cat("5. violin_plot.png saved\n")

cat("\nAll plots saved to plots/\n")
