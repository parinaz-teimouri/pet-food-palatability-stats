user_lib <- file.path(path.expand("~"), "R", "library")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(user_lib)
