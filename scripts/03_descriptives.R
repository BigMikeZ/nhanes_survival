library(tidyverse)
library(gtsummary)
library(survey)

# Some further cleaning and transformation
nhanes_joint <- read_rds("data/processed/nhanes_joint.rds")
nhanes_joint <- nhanes_joint |> 
  mutate(
    WTINT2YR = as.numeric(WTINT2YR) / 5,
    SDMVSTRA = as.numeric(SDMVSTRA),
    SDMVPSU = as.numeric(SDMVPSU),
    RIDRETH1 = as_factor(RIDRETH1),
    HSD010 = factor(HSD010, 
                    levels = c("Excellent", "Very good", "Good", "Fair", "Poor"), 
                    ordered = TRUE),
    DIQ010 = case_when(
      DIQ010 == "Yes"                   ~ "Yes",
      DIQ010 %in% c("No", "Borderline") ~ "No",
      TRUE                              ~ NA_character_
    ), 
    cvd_history = as_factor(case_when(
      MCQ160C == "Yes" | MCQ160E == "Yes" ~ "Yes",
      MCQ160C == "No"  | MCQ160E == "No"  ~ "No",
      TRUE                                ~  NA_character_
    )
   )  
  )
saveRDS(nhanes_joint, "data/processed/nhanes_joint.rds")

# Create svydesign object with id, stratas, and weights
nhanes_survey <- svydesign(
  data = nhanes_joint, 
  strata = ~SDMVSTRA, 
  id = ~SDMVPSU, 
  nest = TRUE, 
  weights = ~WTINT2YR
)

str(nhanes_joint)

# Create gt summary table grouped by marital status
nhanes_table <- tbl_svysummary(
  nhanes_survey, 
  by = DMDMARTL,
  include = c(RIDAGEYR, RIAGENDR, DMDEDUC2, INDFMPIR, RIDRETH1, BMXBMI, SMQ020, PAQ605, 
              BPQ020, DIQ010, HSD010, cvd_history),
  label = list(
    RIDAGEYR       ~  "Age (years)",
    RIAGENDR       ~  "Sex",
    DMDEDUC2       ~  "Education",
    INDFMPIR       ~  "Family income-to-poverty ratio",
    RIDRETH1       ~  "Ethnicity",
    BMXBMI         ~  "BMI",
    SMQ020         ~  "Ever smoked 100 cigarettes, Yes",
    PAQ605         ~  "Vigorous physical activity, Yes",
    cvd_history    ~  "Cardiovascular disease history, Yes",
    BPQ020         ~  "Hypertension, Yes",
    DIQ010         ~  "Diabetes, Yes",
    HSD010         ~  "Self-rated health"
  ) 
) |> 
  add_p() |> 
  add_overall()

nhanes_table

# Save table
nhanes_table |> 
  as_gt() |> 
  gt::gtsave("output/tables/table1.html")