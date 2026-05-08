library(tidyverse)

# Import and clean module data
module_patterns <- c(DEMO = "^DEMO", BMX = "^BMX", SMQ = "^SMQ", 
              PAQ = "^PAQ", MCQ = "^MCQ", BPQ = "^BPQ", DIQ = "^DIQ", HSQ = "^HSQ")
module_files <- map(module_patterns, function(pat) {
  list.files("data/raw/nhanes", pattern = pat, full.names = TRUE)
}) 
str(module_files)

module_list <- map(module_files, function(f) {
  map_df(f, function(f) {
    read_rds(f) |>
      mutate(across(everything(), as.character))
  })
})

str(module_list)
glimpse(module_list$DEMO)

nhanes_merged <- module_list$DEMO |> 
  left_join(module_list$BMX, join_by("SEQN")) |> 
  left_join(module_list$SMQ, join_by("SEQN")) |> 
  left_join(module_list$PAQ, join_by("SEQN")) |> 
  left_join(module_list$MCQ, join_by("SEQN")) |> 
  left_join(module_list$BPQ, join_by("SEQN")) |> 
  left_join(module_list$DIQ, join_by("SEQN")) |> 
  left_join(module_list$HSQ, join_by("SEQN"))
nrow(nhanes_merged)
ncol(nhanes_merged)

nhanes_clean <- nhanes_merged |> 
  select(SEQN, RIDAGEYR, RIAGENDR, DMDMARTL, DMDEDUC2, INDFMPIR, RIDRETH1, SDDSRVYR, 
         WTINT2YR, SDMVPSU, SDMVSTRA, BMXBMI, SMQ020, PAQ605, MCQ160C, MCQ160E, BPQ020,
         DIQ010, HSD010)
ncol(nhanes_clean)

nhanes_clean <- nhanes_clean |> 
  mutate(
    RIDAGEYR = as.numeric(RIDAGEYR),
    INDFMPIR = as.numeric(INDFMPIR),
    BMXBMI = as.numeric(BMXBMI),
    RIAGENDR = as_factor(case_when(
      RIAGENDR == "Male" ~ "Male",
      RIAGENDR == "Female" ~ "Female",
      TRUE ~ NA_character_
    )),
    DMDMARTL = as_factor(case_when(
      DMDMARTL == "Married"                                     ~ "Married",
      DMDMARTL %in% c("Divorced", "Separated", "Widowed")       ~ "Previously married",
      DMDMARTL %in% c("Never married", "Living with partner")   ~ "Never married",
      TRUE ~ NA_character_
    )),
    DMDEDUC2 = as_factor(case_when(
      DMDEDUC2 %in% c("Less than 9th grade", "Less Than 9th Grade")                                                               ~ "Less than 9th grade",
      DMDEDUC2 %in% c("9-11th Grade (Includes 12th grade with no diploma)", "9-11th grade (Includes 12th grade with no diploma)") ~ "9-11th grade",
      DMDEDUC2 %in% c("High School Grad/GED or Equivalent", "   High school graduate/GED or equivalent")                          ~ "High school grad",
      DMDEDUC2 %in% c("Some College or AA degree", "Some college or AA degree")                                                   ~ "Some college",
      DMDEDUC2 %in% c("College Graduate or above", "College graduate or above")                                                   ~ "College grad or above",
      TRUE ~ NA_character_
    )),
    SMQ020 = as_factor(case_when(
      SMQ020 == "Yes" ~ "Yes",
      SMQ020 == "No" ~ "No",
      TRUE ~ NA_character_
    )),
    PAQ605 = as_factor(case_when(
      PAQ605 == "Yes" ~ "Yes",
      PAQ605 == "No" ~ "No",
      TRUE ~ NA_character_
    )),
    BPQ020 = as_factor(case_when(
      BPQ020 == "Yes" ~ "Yes",
      BPQ020 == "No" ~ "No",
      TRUE ~ NA_character_
    )),
    DIQ010 = as_factor(case_when(
      DIQ010 == "Yes" ~ "Yes",
      DIQ010 == "No" ~ "No",
      DIQ010 == "Borderline" ~ "Borderline",
      TRUE ~ NA_character_
    )),
    MCQ160C = as_factor(case_when(
      MCQ160C == "Yes" ~ "Yes",
      MCQ160C == "No" ~ "No",
      TRUE ~ NA_character_
    )),
    MCQ160E = as_factor(case_when(
      MCQ160E == "Yes" ~ "Yes",
      MCQ160E == "No" ~ "No",
      TRUE ~ NA_character_
    )),
    HSD010 = as_factor(case_when(
      HSD010 %in% c("Excellent", "Excellent,") ~ "Excellent",
      HSD010 == "Very good," ~ "Very good",
      HSD010 == "Good," ~ "Good",
      HSD010 == "Fair, or" ~ "Fair",
      HSD010 == "Poor?" ~ "Poor",
      TRUE ~ NA_character_
    ))
  ) |> 
  filter(RIDAGEYR >= 40) 

summary(nhanes_clean)
glimpse(nhanes_clean)

# Import and clean mortality linkage data
mortality_files <- list.files("data/raw/mortality", full.names = TRUE)
mortality_files
mortality_merged <- map_df(mortality_files, function(f) {
  read_fwf(
    f,
    fwf_positions(c(1, 15, 16, 43), c(6, 15, 16, 45), c("SEQN", "eligstat", "mortstat", "permth_int"))
  ) |> 
    mutate(across(everything(), as.character))
})
str(mortality_merged)
glimpse(mortality_merged)
mortality_merged <- mortality_merged |> 
  filter(eligstat == "1")
nrow(mortality_merged)

nhanes_joint <- nhanes_clean |> 
  left_join(mortality_merged, join_by("SEQN")) |> 
  mutate(
    eligstat = as_factor(eligstat),
    mortstat = as.numeric(mortstat),
    permth_int = as.numeric(permth_int)
  )
str(nhanes_joint)
summary(nhanes_joint)

nhanes_joint <- nhanes_joint |> 
  filter(!is.na(mortstat))
summary(nhanes_joint)

saveRDS(nhanes_joint, "data/processed/nhanes_joint.rds")

