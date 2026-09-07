library(tidyverse)
library(haven)
library(nhanesA)
library(usethis)

git_vaccinate()

dir.create("data/raw/nhanes", recursive = TRUE, showWarnings = FALSE)
dir.create("data/raw/mortality", recursive = TRUE, showWarnings = FALSE)

suffixes <- c("D", "E", "F", "G", "H")
modules <- list(
  demo = "DEMO",
  bmx  = "BMX",
  smq  = "SMQ",
  paq  = "PAQ",
  mcq  = "MCQ",
  bpq  = "BPQ",
  diq  = "DIQ",
  hsq  = "HSQ"
)

walk(suffixes, function(suf) {
  walk(unlist(modules, use.names = FALSE), function(mod) {
    table_name <- paste0(mod, "_", suf)
    dest       <- glue::glue("data/raw/nhanes/{table_name}.rds")
    if (!file.exists(dest)) {
      message("Fetching: ", table_name)
      tryCatch({
        df <- nhanes(table_name)
        saveRDS(df, dest)
        message("  Saved: ", dest)
      }, error = function(e) {
        message("  FAILED: ", table_name, " — ", e$message)
      })
    } else {
      message("Already exists, skipping: ", table_name)
    }
  })
})

mort_base <- "https://ftp.cdc.gov/pub/Health_Statistics/NCHS/datalinkage/linked_mortality"

mort_files <- c(
  "NHANES_2005_2006_MORT_2019_PUBLIC.dat",
  "NHANES_2007_2008_MORT_2019_PUBLIC.dat",
  "NHANES_2009_2010_MORT_2019_PUBLIC.dat",
  "NHANES_2011_2012_MORT_2019_PUBLIC.dat",
  "NHANES_2013_2014_MORT_2019_PUBLIC.dat"
)

walk(mort_files, function(f) {
  dest <- file.path("data/raw/mortality", f)
  if (!file.exists(dest)) {
    message("Downloading mortality file: ", f)
    tryCatch(
      download.file(file.path(mort_base, f), dest, mode = "wb", quiet = TRUE),
      error = function(e) message("  FAILED: ", f, " — ", e$message)
    )
  } else {
    message("Already exists, skipping: ", f)
  }
})

message("\nDone. Check data/raw/ for any FAILED files.")
