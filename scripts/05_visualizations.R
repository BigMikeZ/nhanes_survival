library(tidyverse)
library(broom)

# Create data for forest plot
tidy_cox_fit <- tidy(cox_fit, exponentiate = TRUE, conf.int = TRUE) 
tidy_cox_fit |> 
  count(term) |> 
  print(n = 23)

plot_data <- tidy_cox_fit |> 
  mutate(
    term = case_when(
      term == "DMDMARTLPreviously married"   ~ "Previously married",
      term == "DMDMARTLMarried"              ~ "Married",
      term == "RIDAGEYR"                     ~ "Age (years)",
      term == "RIAGENDRFemale"               ~ "Female",
      term == "BPQ020Yes"                    ~ "Hypertension history",
      term == "DIQ010Yes"                    ~ "Diabetes history",
      term == "HSD010Fair"                   ~ "Self-rated health fair",
      term == "HSD010Good"                   ~ "Self-rated health good",
      term == "HSD010Poor"                   ~ "Self-rated health poor",
      term == "HSD010Very good"              ~ "Self-rated health very good",
      term == "INDFMPIR"                     ~ "Family income to poverty ratio",
      term == "PAQ605Yes"                    ~ "Vigorous physical activity",
      term == "SMQ020Yes"                    ~ "Smoking history",
      term == "cvd_historyYes"               ~ "Cardiovascular disease history"
    )
  ) |> 
  filter(!is.na(term))
plot_data

# Build forest plot
plot_data |> 
  ggplot(aes(x = estimate, y = fct_reorder(term, estimate), 
             color = term %in% c("Married", "Previously married"))
         ) + 
  geom_point(size = 2) + 
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), height = 0.3) +
  geom_vline(aes(xintercept = 1), linetype = "dashed") +
  labs(
    title = "Hazard Ratios for All-cause Mortality",
    x = "Hazard Ratio (95% CI)",
    y = "",
    caption = "*Age is expressed per year; the hazard ratio per decade would be approximately 2.51."
  ) +
  theme_minimal() +
  scale_color_manual(values = c("grey40", "steelblue"), guide = "none")

# Save plot
dir.create("output/figures")
ggsave("output/figures/forest_plot.png", width = 8, height = 6, dpi = 300)
  