# .Rprofile — Runs on R startup in this project directory
# Sets user-writable library path for this project

user_lib <- file.path(Sys.getenv("HOME"), "R", "library")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(user_lib)
