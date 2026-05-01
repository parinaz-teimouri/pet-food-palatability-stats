user_lib <- file.path(Sys.getenv("HOME"), "R", "library")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(user_lib)

packages <- c(
  "tidyverse",
  "lubridate",
  "car",
  "emmeans",
  "effectsize",
  "corrplot",
  "arrow",
  "knitr"
)

installed <- rownames(installed.packages(lib.loc = .libPaths()))
to_install <- setdiff(packages, installed)

if (length(to_install) > 0) {
  message("Installing: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cran.r-project.org",
                   lib = user_lib)
} else {
  message("All packages already installed.")
}
