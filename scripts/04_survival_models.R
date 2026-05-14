library(tidyverse)
library(survey)
library(survival)
library(survminer)
library(gtsummary)

nhanes_joint <- readRDS("data/processed/nhanes_joint.rds")

# Create Surv object
nhanes_joint <- nhanes_joint |> 
  mutate(
    surv_object = Surv(permth_int, mortstat),
  )
head(nhanes_joint$surv_object)

# Create surveydesign object and km curve
nhanes_survey <- svydesign(
  data = nhanes_joint, 
  strata = ~SDMVSTRA, 
  id = ~SDMVPSU, 
  nest = TRUE, 
  weights = ~WTINT2YR
)
km_fit <- svykm(surv_object ~ DMDMARTL, design = nhanes_survey)
plot(km_fit)

# Build cox model
cox_fit <- svycoxph(
                    surv_object ~ DMDMARTL + RIDAGEYR + RIAGENDR + DMDEDUC2 +
                    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
                    DIQ010 + HSD010,
                    design = nhanes_survey
                    )
summary(cox_fit)

# Inspect significant missing values from different variables
summary(nhanes_joint)
missing_table <- nhanes_joint |>
  mutate(in_model = !is.na(BMXBMI) & !is.na(PAQ605) & 
           !is.na(HSD010) & !is.na(INDFMPIR) & !is.na(DMDEDUC2)) |> 
  select(in_model, mortstat, RIDAGEYR, RIAGENDR, DMDMARTL, DMDEDUC2, 
         RIDRETH1, BMXBMI, SMQ020, PAQ605, cvd_history, 
         BPQ020, DIQ010, HSD010, INDFMPIR, mortstat) |>
  tbl_summary(
    by = in_model,
    label = list(
      mortstat       ~  "Mortality",
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
  add_p()
missing_table |> 
  as_gt() |> 
  gt::gtsave("output/tables/missing_table.html")

# Test proportional hazard assumption
cox.zph(cox_fit)

# Stratified models
nhanes_male <- subset(nhanes_survey, RIAGENDR == "Male")
nhanes_female <- subset(nhanes_survey, RIAGENDR == "Female")

nhanes_male_cox <- svycoxph(
  surv_object ~ DMDMARTL + RIDAGEYR + DMDEDUC2 +
    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
    DIQ010 + HSD010, 
  design = nhanes_male
  )
nhanes_female_cox <- svycoxph(
  surv_object ~ DMDMARTL + RIDAGEYR + DMDEDUC2 +
    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
    DIQ010 + HSD010,
  design = nhanes_female
  )

nhanes_4059 <- subset(nhanes_survey, RIDAGEYR < 60)
nhanes_6074 <- subset(nhanes_survey, RIDAGEYR >= 60 &  RIDAGEYR < 75)
nhanes_75nplus <- subset(nhanes_survey, RIDAGEYR >= 75)
nhanes_4059_cox <- svycoxph(
  surv_object ~ DMDMARTL + RIAGENDR + DMDEDUC2 +
    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
    DIQ010 + HSD010,, 
  design = nhanes_4059)
nhanes_6074_cox <- svycoxph(
  surv_object ~ DMDMARTL + RIAGENDR + DMDEDUC2 +
    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
    DIQ010 + HSD010,, 
  design = nhanes_6074)
nhanes_75nplus <- svycoxph(
  surv_object ~ DMDMARTL + RIAGENDR + DMDEDUC2 +
    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
    DIQ010 + HSD010,, 
  design = nhanes_75nplus)

# Fit interaction terms
sex_interaction_cox <- svycoxph(
  surv_object ~ DMDMARTL*RIAGENDR + RIDAGEYR + DMDEDUC2 +
    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
    DIQ010 + HSD010,
  design = nhanes_survey
)
summary(sex_interaction_cox)

nhanes_joint_binned_age <- nhanes_joint |> 
  mutate(
    binned_age = case_when(
      RIDAGEYR < 60   ~  "40-59",
      RIDAGEYR < 75   ~  "60-74",
      RIDAGEYR >= 75  ~  "75 and plus"
    )
  )

nhanes_binned_age_survey <- svydesign(
  data = nhanes_joint_binned_age, 
  strata = ~SDMVSTRA, 
  id = ~SDMVPSU, 
  nest = TRUE, 
  weights = ~WTINT2YR
)

age_interaction_cox <- svycoxph(
  surv_object ~ DMDMARTL*binned_age + RIAGENDR + DMDEDUC2 +
    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
    DIQ010 + HSD010,
  design = nhanes_binned_age_survey
)
summary(age_interaction_cox)

# Save model outputs
dir.create("output/models")

saveRDS(cox_fit, "output/models/cox_fit.rds")
saveRDS(sex_interaction_cox, "output/models/cox_sex_interaction.rds")
saveRDS(age_interaction_cox, "output/models/cox_age_interaction.rds")
