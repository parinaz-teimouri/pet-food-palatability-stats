source("_init.R")
library(tidyverse)
library(car)
library(emmeans)
library(effectsize)
library(knitr)

df <- read_csv("data/processed/feeding_trials_clean.csv", show_col_types = FALSE)

cat("=== Statistical Analysis Pipeline ===\n")
cat("Analyzing", nrow(df), "observations\n\n")

format_p <- function(p) {
  case_when(
    p < 0.001  ~ "< 0.001",
    p < 0.01   ~ sprintf("%.3f", p),
    p < 0.05   ~ sprintf("%.3f", p),
    TRUE        ~ sprintf("%.3f", p)
  )
}

sig_mark <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01  ~ "**",
    p < 0.05  ~ "*",
    TRUE       ~ "ns"
  )
}

results <- list()

cat("--- Test 1: Two-Way ANOVA ---\n")
cat("H0: No effect of species, formula, or their interaction on palatability\n\n")

anova_model <- lm(palatability_score ~ species * formula, data = df)
anova_table <- Anova(anova_model, type = "II")

print(anova_table)

anova_results <- tibble(
  Effect   = rownames(anova_table),
  F_value  = round(anova_table$`F value`, 2),
  p_value  = anova_table$`Pr(>F)`,
  Signif   = sig_mark(anova_table$`Pr(>F)`)
)

cat("\n")

cat("--- Effect Sizes (Eta-squared) ---\n")
eta <- eta_squared(anova_model)
print(eta)
cat("\n")

cat("--- Assumption Checks ---\n")

shapiro_res <- shapiro.test(residuals(anova_model))
cat(sprintf("Shapiro-Wilk test on residuals: W = %.4f, p = %s\n",
            shapiro_res$statistic, format_p(shapiro_res$p.value)))

levene_res <- leveneTest(palatability_score ~ interaction(species, formula), data = df)
cat(sprintf("Levene's test: F = %.2f, p = %s\n",
            levene_res$`F value`[1], format_p(levene_res$`Pr(>F)`[1])))

assumption_note <- sprintf(
  "Normality: W=%.3f (p=%s). Levene's: F=%.2f (p=%s).",
  shapiro_res$statistic, format_p(shapiro_res$p.value),
  levene_res$`F value`[1], format_p(levene_res$`Pr(>F)`[1])
)
cat("\n")

cat("--- Test 3: Post-hoc Tukey HSD (by formula) ---\n")

emmeans_formula <- emmeans(anova_model, ~ formula)
tukey_res <- pairs(emmeans_formula, adjust = "tukey")
print(summary(tukey_res))

tukey_results <- as_tibble(summary(tukey_res)) %>%
  mutate(
    p_adj = round(p.value, 4),
    Signif = sig_mark(p.value),
    contrast = paste0(contrast)
  )

cat("\n")

emmeans_table <- as_tibble(summary(emmeans_formula)) %>%
  mutate(across(where(is.numeric), ~ round(., 2)))

cat("Estimated marginal means by formula:\n")
print(emmeans_table)
cat("\n")

cat("--- Test 4: Independent t-test (Dog vs Cat) ---\n")
cat("H0: No difference in palatability score between dogs and cats\n\n")

ttest_pal <- t.test(palatability_score ~ species, data = df)
print(ttest_pal)

coh_d_pal <- cohens_d(palatability_score ~ species, data = as.data.frame(df))
cat(sprintf("\nCohen's d: %.3f\n", coh_d_pal$Cohens_d[1]))

ttest_pal_result <- tibble(
  Test     = "t-test (Dog vs Cat)",
  t_stat   = round(ttest_pal$statistic, 3),
  df       = round(ttest_pal$parameter, 1),
  p_value  = ttest_pal$p.value,
  Cohen_d  = round(coh_d_pal$Cohens_d[1], 3),
  Signif   = sig_mark(ttest_pal$p.value)
)
cat("\n")

cat("--- Test 5: Welch's t-test (Consumption) ---\n")
cat("H0: No difference in consumed amount between dogs and cats\n\n")

ttest_cons <- t.test(consumed_amount_grams ~ species, data = df, var.equal = FALSE)
print(ttest_cons)

ttest_cons_result <- tibble(
  Test     = "Welch t-test (Consumption)",
  t_stat   = round(ttest_cons$statistic, 3),
  df       = round(ttest_cons$parameter, 1),
  p_value  = ttest_cons$p.value,
  Signif   = sig_mark(ttest_cons$p.value)
)
cat("\n")

cat("--- Test 6: Chi-squared test (High Palatability × Species) ---\n")
cat("H0: High palatability (above median) is independent of species\n\n")

median_score <- median(df$palatability_score, na.rm = TRUE)
cat("Median palatability score:", median_score, "\n\n")

chi_data <- df %>%
  filter(!is.na(palatability_score)) %>%
  mutate(
    high_palatability = ifelse(palatability_score > median_score, "High", "Low")
  )

contingency_table <- table(chi_data$species, chi_data$high_palatability)
cat("Contingency table (Species × Palatability Level):\n")
print(contingency_table)

chi_res <- chisq.test(contingency_table)
cat("\n")
print(chi_res)

chi_result <- tibble(
  Test       = "Chi-squared (High Palatability × Species)",
  Chi_sq     = round(chi_res$statistic, 3),
  df         = chi_res$parameter,
  p_value    = chi_res$p.value,
  Cramers_V  = round(sqrt(chi_res$statistic / sum(contingency_table)), 3),
  Signif     = sig_mark(chi_res$p.value)
)
cat("\n")

cat("--- Test 7: Pearson Correlation (Age vs. Consumption) ---\n")
cat("H0: No linear relationship between age and amount consumed\n\n")

cor_res <- cor.test(df$age_months, df$consumed_amount_grams, use = "complete.obs")
print(cor_res)

cor_result <- tibble(
  Test     = "Pearson (Age vs. Consumption)",
  r        = round(cor_res$estimate, 3),
  t_stat   = round(cor_res$statistic, 3),
  p_value  = cor_res$p.value,
  CI       = paste0("[", round(cor_res$conf.int[1], 3), ", ",
                    round(cor_res$conf.int[2], 3), "]"),
  Signif   = sig_mark(cor_res$p.value)
)
cat("\n")

cat("--- Correlation Matrix ---\n")

numeric_vars <- df %>%
  select(palatability_score, time_to_first_bite, consumed_amount_grams,
         age_months, weight_kg) %>%
  drop_na()

cor_matrix <- round(cor(numeric_vars), 3)
print(cor_matrix)

report_lines <- c(
  "# Statistical Analysis Results",
  "",
  paste0("Dataset: `data/processed/feeding_trials_clean.csv` ",
         "(", nrow(df), " observations)"),
  "",
  "---",
  "",
  "## 1. Two-Way ANOVA: Palatability Score ~ Species * Formula",
  "",
  "```",
  capture.output(print(anova_table)),
  "```",
  "",
  "**Effect sizes (eta-squared):**",
  "",
  paste0("- Species: eta^2 = ", round(eta$Eta2[1], 3)),
  paste0("- Formula: eta^2 = ", round(eta$Eta2[2], 3)),
  paste0("- Interaction: eta^2 = ", round(eta$Eta2[3], 3)),
  "",
  "## 2. Assumption Checks",
  "",
  paste0("- **Normality (Shapiro-Wilk):** W = ", round(shapiro_res$statistic, 4),
         ", p = ", format_p(shapiro_res$p.value)),
  paste0("- **Homogeneity (Levene's):** F = ", round(levene_res$`F value`[1], 2),
         ", p = ", format_p(levene_res$`Pr(>F)`[1])),
  "",
  "## 3. Post-hoc Tukey HSD (Formula Comparisons)",
  "",
  "```",
  capture.output(print(summary(tukey_res))),
  "```",
  "",
  "**Estimated marginal means:**",
  "",
  knitr::kable(emmeans_table, format = "pipe"),
  "",
  "## 4. Independent t-test: Dog vs Cat (Palatability)",
  "",
  paste0("- t = ", round(ttest_pal$statistic, 3),
         ", df = ", round(ttest_pal$parameter, 1),
         ", p = ", format_p(ttest_pal$p.value)),
  paste0("- Cohen's d = ", round(coh_d_pal$Cohens_d[1], 3)),
  "",
  "## 5. Welch's t-test: Dog vs Cat (Consumption)",
  "",
  paste0("- t = ", round(ttest_cons$statistic, 3),
         ", df = ", round(ttest_cons$parameter, 1),
         ", p = ", format_p(ttest_cons$p.value)),
  "",
  "## 6. Chi-squared: High Palatability × Species",
  "",
  paste0("Median split at ", median_score, ". Each pet tests one formula (not a crossover),"),
  "so we test whether achieving high palatability is associated with species.",
  "",
  "```",
  capture.output(print(contingency_table)),
  "```",
  paste0("- Chi-sq = ", round(chi_res$statistic, 3),
         ", df = ", chi_res$parameter,
         ", p = ", format_p(chi_res$p.value)),
  paste0("- Cramer's V = ", round(sqrt(chi_res$statistic / sum(contingency_table)), 3)),
  "",
  "## 7. Pearson Correlation: Age vs. Consumption",
  "",
  paste0("- r = ", round(cor_res$estimate, 3),
         ", t = ", round(cor_res$statistic, 3),
         ", p = ", format_p(cor_res$p.value)),
  paste0("- 95% CI: [", round(cor_res$conf.int[1], 3), ", ",
         round(cor_res$conf.int[2], 3), "]"),
  "",
  "## 8. Correlation Matrix",
  "",
  "```",
  capture.output(print(cor_matrix)),
  "```"
)

writeLines(report_lines, "reports/statistical_results.md")
cat("Results saved to reports/statistical_results.md\n")
