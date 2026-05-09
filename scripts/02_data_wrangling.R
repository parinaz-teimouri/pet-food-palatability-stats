source("_init.R")
library(tidyverse)
library(lubridate)

df <- read_csv("data/raw/feeding_trials.csv",
               show_col_types = FALSE,
               na = c("", "NA", "N/A", "n/a"))

cat("Raw data loaded:", nrow(df), "rows,", ncol(df), "columns\n")
initial_rows <- nrow(df)

cat_cols <- c("species", "formula", "lab_technician", "breed")
df <- df %>%
  mutate(across(all_of(cat_cols), ~ str_trim(.)))

df <- df %>%
  mutate(formula = case_when(
    formula %in% c("A", "a") ~ "A",
    formula %in% c("B", "b") ~ "B",
    formula %in% c("C", "c") ~ "C",
    TRUE ~ formula
  ))

cat("String standardization: done\n")

raw_dates <- as.character(df$trial_date)
parsed <- as.Date(NA_character_, origin = "1970-01-01")[seq_along(raw_dates)]

iso_mask <- grepl("^\\d{4}-\\d{2}-\\d{2}$", raw_dates)
parsed[iso_mask] <- suppressWarnings(ymd(raw_dates[iso_mask]))

dot_mask <- grepl("^\\d{4}\\.\\d{2}\\.\\d{2}$", raw_dates) & is.na(parsed)
parsed[dot_mask] <- suppressWarnings(ymd(raw_dates[dot_mask]))

mdash_mask <- grepl("\\d{1,2}-[A-Za-z]{3}-\\d{4}", raw_dates) & is.na(parsed)
parsed[mdash_mask] <- suppressWarnings(dmy(raw_dates[mdash_mask]))

mcomma_mask <- grepl("^[A-Za-z]{3} \\d{1,2}, \\d{4}$", raw_dates) & is.na(parsed)
parsed[mcomma_mask] <- suppressWarnings(mdy(raw_dates[mcomma_mask]))

slash_mask <- grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", raw_dates) & is.na(parsed)
if (any(slash_mask)) {
  mdy_parsed <- suppressWarnings(mdy(raw_dates[slash_mask]))
  dmy_parsed <- suppressWarnings(dmy(raw_dates[slash_mask]))
  slash_idx <- which(slash_mask)
  for (i in seq_along(slash_idx)) {
    if (!is.na(mdy_parsed[i])) {
      parsed[slash_idx[i]] <- mdy_parsed[i]
    } else if (!is.na(dmy_parsed[i])) {
      parsed[slash_idx[i]] <- dmy_parsed[i]
    }
  }
}

still_na <- is.na(parsed) & !is.na(raw_dates)
parsed[still_na] <- suppressWarnings(as.Date(raw_dates[still_na]))

df$trial_date <- parsed

n_date_fails <- sum(is.na(df$trial_date) & !is.na(df$pet_id))
n_date_ok <- sum(!is.na(df$trial_date))
cat("Date parsing:", n_date_ok, "parsed,", n_date_fails, "failed → set to NA\n")

dup_cols <- setdiff(names(df), "row_number")
df <- df %>%
  distinct(across(all_of(dup_cols)), .keep_all = TRUE)

cat("After dedup:", nrow(df), "rows (removed", initial_rows - nrow(df), ")\n")

outlier_flags <- df %>%
  mutate(
    is_outlier = (!is.na(palatability_score) &
                    (palatability_score < 1 | palatability_score > 10)) |
                 (!is.na(consumed_amount_grams) &
                    (consumed_amount_grams < 5 | consumed_amount_grams > 200)) |
                 (!is.na(time_to_first_bite) &
                    (time_to_first_bite < 1 | time_to_first_bite > 60))
  )

n_outliers <- sum(outlier_flags$is_outlier, na.rm = TRUE)
df <- df %>% filter(!outlier_flags$is_outlier)

cat("Removed", n_outliers, "outlier rows\n")

num_cols <- c("palatability_score", "time_to_first_bite",
              "consumed_amount_grams", "age_months", "weight_kg")
df <- df %>%
  mutate(across(all_of(num_cols), ~ as.numeric(.)))

impute_col_with_group_median <- function(data, col_name) {
  data %>%
    group_by(species, formula) %>%
    mutate(!!col_name := ifelse(
      is.na(.data[[col_name]]),
      median(.data[[col_name]], na.rm = TRUE),
      .data[[col_name]]
    )) %>%
    ungroup()
}

before_pal_nas <- sum(is.na(df$palatability_score))
before_cons_nas <- sum(is.na(df$consumed_amount_grams))

df <- df %>%
  impute_col_with_group_median("palatability_score") %>%
  impute_col_with_group_median("consumed_amount_grams")

cat("Imputed palatability_score:", before_pal_nas, "NAs →",
    sum(is.na(df$palatability_score)), "remaining\n")
cat("Imputed consumed_amount_grams:", before_cons_nas, "NAs →",
    sum(is.na(df$consumed_amount_grams)), "remaining\n")

df <- df %>%
  mutate(
    formula_label = recode(formula,
      "A" = "Control",
      "B" = "New Protein",
      "C" = "New Flavour Coating"
    ),
    weight_z = (weight_kg - mean(weight_kg, na.rm = TRUE)) /
               sd(weight_kg, na.rm = TRUE),
    bite_speed = case_when(
      time_to_first_bite <= 10 ~ "Fast",
      time_to_first_bite <= 25 ~ "Medium",
      TRUE ~ "Slow"
    )
  )

if ("row_number" %in% names(df)) {
  df <- df %>% select(-row_number)
}

df <- df %>%
  mutate(
    palatability_score = round(palatability_score, 1),
    time_to_first_bite = round(time_to_first_bite, 1),
    consumed_amount_grams = round(consumed_amount_grams, 1),
    weight_kg = round(weight_kg, 1)
  )

write_csv(df, "data/processed/feeding_trials_clean.csv")

cat("\n=== Cleaning Summary ===\n")
cat("Input rows:     ", initial_rows, "\n")
cat("Output rows:    ", nrow(df), "\n")
cat("Deduped rows:   ", initial_rows - nrow(df) + n_outliers, "\n")
cat("Outlier rows:   ", n_outliers, "\n")
cat("Clean data:     ", nrow(df), "rows ×", ncol(df), "columns\n")
cat("Saved to:       data/processed/feeding_trials_clean.csv\n")
