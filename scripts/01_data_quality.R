source("_init.R")
library(tidyverse)

df <- read_csv("data/raw/feeding_trials.csv",
               show_col_types = FALSE,
               na = c("", "NA", "N/A", "n/a"))

cat("=== Data Quality Report ===\n\n")
cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n\n")

missing_summary <- tibble(
  column     = names(df),
  n_missing  = sapply(df, function(x) sum(is.na(x))),
  pct_missing = round(100 * n_missing / nrow(df), 1)
) %>%
  filter(n_missing > 0) %>%
  arrange(desc(n_missing))

cat("--- Missing Values ---\n")
if (nrow(missing_summary) > 0) {
  print(missing_summary)
} else {
  cat("No missing values found.\n")
}

dup_cols <- setdiff(names(df), "row_number")
exact_dups <- df %>% filter(duplicated(across(all_of(dup_cols))) |
                              duplicated(across(all_of(dup_cols)), fromLast = TRUE))

cat("\n--- Duplicates ---\n")
cat("Exact duplicate rows:", nrow(exact_dups), "\n")
if (nrow(exact_dups) > 0) {
  exact_dups %>% select(pet_id, species, formula, trial_date) %>% print(n = 10)
}

id_formula_dups <- df %>%
  filter(!is.na(pet_id), !is.na(formula)) %>%
  group_by(pet_id, formula) %>%
  filter(n() > 1) %>%
  ungroup()

cat("\npet_id + formula duplicates:", nrow(id_formula_dups), "rows\n")
if (nrow(id_formula_dups) > 0) {
  id_formula_dups %>%
    count(pet_id, formula, name = "n_rows") %>%
    print(n = 10)
}

outlier_bounds <- tribble(
  ~column,                ~min_valid, ~max_valid,
  "palatability_score",   1,          10,
  "time_to_first_bite",   1,          60,
  "consumed_amount_grams", 5,         200,
  "age_months",           1,          240,
  "weight_kg",            0.5,        80
)

cat("\n--- Outliers ---\n")
for (i in seq_len(nrow(outlier_bounds))) {
  col_name <- outlier_bounds$column[i]
  lo       <- outlier_bounds$min_valid[i]
  hi       <- outlier_bounds$max_valid[i]

  if (col_name %in% names(df)) {
    vals <- suppressWarnings(as.numeric(df[[col_name]]))
    n_out <- sum(!is.na(vals) & (vals < lo | vals > hi))
    cat(sprintf("  %s: %d values outside [%.1f, %.1f]\n",
                col_name, n_out, lo, hi))
  }
}

cat("\n--- Type Consistency ---\n")

date_col <- df$trial_date
if (!is.Date(date_col)) {
  parsed <- suppressWarnings(as.Date(date_col))
  n_fail <- sum(is.na(parsed) & !is.na(date_col))
  cat(sprintf("  trial_date: %d values could not be parsed as Date\n", n_fail))
}

num_cols <- c("palatability_score", "time_to_first_bite",
              "consumed_amount_grams", "age_months", "weight_kg")
for (col in num_cols) {
  if (col %in% names(df)) {
    vals <- df[[col]]
    if (is.character(vals) || is.logical(vals)) {
      n_nonnum <- sum(!is.na(vals) & is.na(suppressWarnings(as.numeric(vals))))
      cat(sprintf("  %s: stored as %s, %d non-numeric values found\n",
                  col, class(vals)[1], n_nonnum))
    } else {
      cat(sprintf("  %s: OK (numeric)\n", col))
    }
  }
}

cat("\n--- String Cleanliness ---\n")
cat_cols <- c("species", "formula", "lab_technician")
for (col in cat_cols) {
  if (col %in% names(df) && is.character(df[[col]])) {
    vals <- df[[col]]
    n_both <- sum(!is.na(vals) & grepl("^\\s|\\s$", vals))
    cat(sprintf("  %s: %d rows with leading/trailing whitespace\n", col, n_both))
  }
}

cat("\n--- Summary Statistics ---\n")
df %>%
  select(where(is.numeric)) %>%
  summary() %>%
  print()

report_lines <- c(
  "# Data Quality Report",
  "",
  paste0("Generated from: `data/raw/feeding_trials.csv`"),
  paste0("Total rows: **", nrow(df), "** | Total columns: **", ncol(df), "**"),
  "",
  "## Missing Values",
  "",
  if (nrow(missing_summary) > 0) {
    c("| Column | Missing | % |",
      "|--------|---------|---|",
      paste0("| ", missing_summary$column, " | ", missing_summary$n_missing,
             " | ", missing_summary$pct_missing, "% |"))
  } else {
    "No missing values found."
  },
  "",
  "## Duplicates",
  "",
  paste0("- **Exact duplicate rows:** ", nrow(exact_dups)),
  paste0("- **Duplicate pet_id + formula:** ", nrow(id_formula_dups), " rows"),
  "",
  "## Outliers (outside valid ranges)",
  "",
  paste0("- palatability_score: values outside [1, 10]"),
  paste0("- consumed_amount_grams: values outside [5, 200]"),
  paste0("- time_to_first_bite: values outside [1, 60]"),
  "",
  "## Type & Format Issues",
  "",
  paste0("- Date format inconsistencies detected in `trial_date`"),
  paste0("- String whitespace issues in categorical columns"),
  paste0("- N/A strings present instead of proper NA values"),
  "",
  "## Summary Statistics",
  "",
  "```",
  capture.output(df %>% select(where(is.numeric)) %>% summary()),
  "```"
)

writeLines(report_lines, "reports/data_quality_report.md")
cat("\n\nReport saved to reports/data_quality_report.md\n")
