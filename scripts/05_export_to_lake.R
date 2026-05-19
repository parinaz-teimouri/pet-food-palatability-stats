source("_init.R")
library(tidyverse)
library(arrow)

df <- read_csv("data/processed/feeding_trials_clean.csv", show_col_types = FALSE)

cat("=== Data Lake Export ===\n\n")
cat("Loaded:", nrow(df), "rows\n")

species_list <- unique(df$species)

for (sp in species_list) {
  partition_data <- df %>% filter(species == sp)
  partition_dir <- file.path("data/lake", paste0("species=", tolower(sp)))
  dir.create(partition_dir, recursive = TRUE, showWarnings = FALSE)

  parquet_path <- file.path(partition_dir, "feeding_trials.parquet")
  write_parquet(partition_data, parquet_path)

  file_size <- file.info(parquet_path)$size
  cat(sprintf("  species=%s: %d rows → %s (%.1f KB)\n",
              tolower(sp), nrow(partition_data), parquet_path, file_size / 1024))
}

cat("\n--- Verification ---\n")
for (sp in species_list) {
  parquet_path <- file.path("data/lake", paste0("species=", tolower(sp)),
                            "feeding_trials.parquet")
  verify_df <- read_parquet(parquet_path)
  cat(sprintf("  Read back %s partition: %d rows, %d columns\n",
              tolower(sp), nrow(verify_df), ncol(verify_df)))
}

cat("\n=== Export Complete ===\n")
cat("Data lake structure:\n")
cat("  data/lake/\n")
for (sp in species_list) {
  cat(sprintf("    species=%s/\n", tolower(sp)))
  cat(sprintf("      feeding_trials.parquet\n"))
}
