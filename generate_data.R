set.seed(42)
source("_init.R")
library(tidyverse)

n_dogs  <- 270
n_cats  <- 230
n_total <- n_dogs + n_cats

dog_breeds <- c("Labrador", "Golden Retriever", "Beagle",
                "German Shepherd", "Poodle")
cat_breeds <- c("Siamese", "Maine Coon", "Bengal",
                "British Shorthair", "Ragdoll")

formulas  <- c("A", "B", "C")
technicians <- c("Dr. Smith", "Dr. Patel", "Dr. Chen", "Dr. Okafor")

formula_means <- c(A = 6.5, B = 7.2, C = 7.8)
species_offset <- c(Dog = 0.3, Cat = -0.3)

make_ids <- function(species, n) {
  prefix <- ifelse(species == "Dog", "DOG", "CAT")
  sprintf("%s-%03d", prefix, seq_len(n))
}

dogs <- tibble(
  pet_id       = make_ids("Dog", n_dogs),
  species      = "Dog",
  breed        = sample(dog_breeds, n_dogs, replace = TRUE),
  age_months   = sample(6:120, n_dogs, replace = TRUE),
  weight_kg    = round(runif(n_dogs, 3, 40), 1),
  formula      = sample(formulas, n_dogs, replace = TRUE),
  batch_id     = sprintf("B2024-%03d", sample(1:15, n_dogs, replace = TRUE)),
  trial_date   = sample(seq(as.Date("2024-01-01"),
                            as.Date("2024-12-31"), by = "day"), n_dogs, replace = TRUE),
  lab_technician = sample(technicians, n_dogs, replace = TRUE),
  notes        = ""
)

cats <- tibble(
  pet_id       = make_ids("Cat", n_cats),
  species      = "Cat",
  breed        = sample(cat_breeds, n_cats, replace = TRUE),
  age_months   = sample(6:120, n_cats, replace = TRUE),
  weight_kg    = round(runif(n_cats, 3, 7), 1),
  formula      = sample(formulas, n_cats, replace = TRUE),
  batch_id     = sprintf("B2024-%03d", sample(1:15, n_cats, replace = TRUE)),
  trial_date   = sample(seq(as.Date("2024-01-01"),
                            as.Date("2024-12-31"), by = "day"), n_cats, replace = TRUE),
  lab_technician = sample(technicians, n_cats, replace = TRUE),
  notes        = ""
)

df <- bind_rows(dogs, cats)

df <- df %>%
  mutate(
    base_score = formula_means[formula] + species_offset[species],
    palatability_score = round(pmin(10, pmax(1, base_score + rnorm(n(), 0, 1.3))), 1),
    time_to_first_bite = round(pmax(2, 30 - 2.5 * palatability_score +
                                       rnorm(n(), 0, 4)), 1),
    consumed_amount_grams = round(pmax(10, 20 + 8 * palatability_score -
                                         ifelse(species == "Cat", 15, 0) +
                                         rnorm(n(), 0, 10)), 1)
  ) %>%
  select(-base_score)

note_options <- c(
  "Refused initial sample",
  "Trial interrupted — pet distracted",
  "Unusual hesitation before eating",
  "Spillage during trial (approx. 10g)",
  "Pet showed strong preference immediately",
  "Slight food intolerance observed post-trial",
  "Container seal was compromised",
  "Technician noted unusual batch texture"
)

note_indices <- sample(seq_len(n_total), size = round(0.05 * n_total))
df$notes[note_indices] <- sample(note_options, length(note_indices), replace = TRUE)

cols_to_miss <- c("palatability_score", "consumed_amount_grams",
                  "weight_kg", "notes")
for (col in cols_to_miss) {
  miss_idx <- sample(seq_len(n_total),
                     size = round(0.08 * n_total))
  df[[col]][miss_idx] <- NA
}

dup_rows <- df[sample(seq_len(n_total), 3), ]
df <- bind_rows(df, dup_rows)

df <- bind_rows(
  df,
  tibble(
    pet_id = c("DOG-999", "CAT-999"),
    species = c("Dog", "Cat"),
    breed = c("Labrador", "Siamese"),
    age_months = c(48, 36),
    weight_kg = c(25.0, 4.5),
    formula = c("B", "C"),
    batch_id = c("B2024-010", "B2024-012"),
    palatability_score = c(15, 0),
    time_to_first_bite = c(5, 60),
    consumed_amount_grams = c(500, 5),
    trial_date = as.Date(c("2024-06-15", "2024-09-20")),
    lab_technician = c("Dr. Smith", "Dr. Chen"),
    notes = c("SUSPICIOUS DATA — likely equipment malfunction",
              "Pet refused all food")
  )
)

n_dates <- nrow(df)
messy_date_indices <- sample(seq_len(n_dates), 6)
original_dates <- df$trial_date[messy_date_indices]
df$trial_date[messy_date_indices] <- c(
  format(original_dates[1], "%m/%d/%Y"),
  format(original_dates[2], "%d-%b-%Y"),
  format(original_dates[3], "%Y.%m.%d"),
  format(original_dates[4], "%d/%m/%Y"),
  format(original_dates[5], "%b %d, %Y"),
  format(original_dates[6], "%Y-%m-%d")
)

na_string_idx <- sample(seq_len(nrow(df)), 4)
df$notes[na_string_idx[1:2]] <- "N/A"
df$weight_kg[na_string_idx[3]] <- "n/a"
df$consumed_amount_grams[na_string_idx[4]] <- "N/A"

whitespace_idx <- sample(seq_len(nrow(df)), 6)
df$species[whitespace_idx[1:2]] <- paste0(" ", df$species[whitespace_idx[1:2]], " ")
df$formula[whitespace_idx[3:4]] <- paste0(df$formula[whitespace_idx[3:4]], "  ")
df$lab_technician[whitespace_idx[5:6]] <- paste0(" ", df$lab_technician[whitespace_idx[5:6]])

df <- df[sample(seq_len(nrow(df))), ]
df <- df %>% mutate(row_number = row_number())

write_csv(df, "data/raw/feeding_trials.csv")
message("Generated ", nrow(df), " rows → data/raw/feeding_trials.csv")
