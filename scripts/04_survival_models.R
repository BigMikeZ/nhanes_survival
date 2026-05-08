library(tidyverse)
library(survey)
library(survival)
library(survminer)

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
                    surv_object ~ DMDMARTL + RIDAGEYR + RIAGENDR + DMDMARTL + DMDEDUC2 +
                    INDFMPIR + RIDRETH1 + BMXBMI + SMQ020 + PAQ605 + cvd_history + BPQ020 +
                    DIQ010 + HSD010,
                    design = nhanes_survey
                    )
summary(cox_fit)

nhanes_joint |>
  mutate(in_model = !is.na(BMXBMI) & !is.na(PAQ605) & 
           !is.na(HSD010) & !is.na(INDFMPIR)) |>
  group_by(in_model) |>
  summarise(
    n = n(),
    deaths = sum(mortstat == 1),
    mean_age = mean(RIDAGEYR)
  )
