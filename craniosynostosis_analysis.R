# =============================================================================
# Craniosynostosis in U.S. Infants: A Parent-Reported Survey Analysis
# Author: Baraah Alshannaq
# M.S. Data Analytics capstone, University of Houston-Downtown (Fall 2023)
#
# What this script does:
#   1. Loads and cleans the survey data (400 responses x 32 questions)
#   2. Turns multi-select answers into yes/no (0/1) indicator columns
#   3. Makes the charts used in the presentation (saved to figures/)
#   4. Runs Fisher's exact tests: craniosynostosis type vs. gender, age at
#      diagnosis, cognitive impact, and speech/language impact
#
# The raw survey data is NOT included in this repository to protect
# participants' privacy. Put the Google Forms export at data/Responses.xlsx.
# =============================================================================


# ---- 0. Setup ---------------------------------------------------------------

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(forcats)
library(ggplot2)
library(RColorBrewer)
library(knitr)

dir.create("figures", showWarnings = FALSE)

# One shared chart style, so every figure looks the same
theme_capstone <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title   = element_text(size = 15, face = "bold"),
      axis.title   = element_text(size = 12, face = "bold"),
      axis.text    = element_text(size = 11, face = "bold", colour = "black"),
      legend.text  = element_text(face = "bold", colour = "black"),
      panel.grid.minor = element_blank()
    )
}
bar_fill <- "#B3CDE3"

# Save a chart to figures/ with consistent size
save_chart <- function(plot, name, width = 8, height = 5) {
  ggsave(file.path("figures", paste0(name, ".png")), plot,
         width = width, height = height, dpi = 300, bg = "white")
  plot
}

# Returns 1 if the text matches the pattern (case-insensitive), otherwise 0.
# Missing answers count as 0.
flag <- function(text, pattern) {
  as.integer(str_detect(replace_na(as.character(text), ""),
                        regex(pattern, ignore_case = TRUE)))
}


# ---- 1. Load data -----------------------------------------------------------

raw <- read_excel("data/Responses.xlsx")

names(raw) <- c(
  "Timestamp", "Consent", "DOB", "Gender", "Race", "US_state",
  "Craniosynostosis_diagnosis", "Birth_type", "Multiple_craniosynostosis_birth",
  "Initial_symptoms", "Genetic_testing", "Types_of_craniosynostosis",
  "Age_at_craniosynostosis_diagnosis", "Primary_method_used_for_diagnosis",
  "Additional_medical_conditions", "Types_of_treatments", "Outcomes",
  "Complications_or_side_effects", "Age_cranial_surgery_performed",
  "Insurance_status", "Hospitalization_years", "Risk_factors",
  "Insights_causes", "Insights_causes_Details", "Cognitive_impact",
  "Cognitive_impact_Details", "Speech_and_language_impact",
  "Speech_and_language_challenges", "Speech_and_language_challenges_Details",
  "Quality_of_life", "Long_term_side_effects", "Satisfactory_level"
)

# The capstone used the 400 responses received in October 2023
raw <- raw %>% filter(Timestamp < as.POSIXct("2023-11-01"))
cat("Rows:", nrow(raw), " Columns:", ncol(raw), "\n")

# Dates of birth: handles real dates, Excel day numbers, and two dates
# typed with a 00xx year (e.g. 10/13/0022 -> 2022)
parse_dob <- function(x) {
  if (inherits(x, c("POSIXct", "Date"))) return(as.Date(x))
  num <- suppressWarnings(as.numeric(x))
  out <- as.Date(num, origin = "1899-12-30")
  typed <- is.na(num) & grepl("/00\\d\\d$", x)
  out[typed] <- as.Date(sub("/00(\\d\\d)$", "/20\\1", x[typed]), "%m/%d/%Y")
  out
}


# ---- 2. Clean single-answer columns -----------------------------------------

# Race: exact matching on the trimmed answer, so combined answers such as
# "Asian and white" are not caught by a shorter pattern like "Asian" first.
race_map <- c(
  "white"                                     = "White",
  "black or african american"                 = "Black or African American",
  "asian"                                     = "Asian",
  "american indian or alaska native"          = "American Indian or Alaska Native",
  "native hawaiian or other pacific islander" = "Native Hawaiian or Other Pacific Islander",
  "middle east"                               = "Asian",
  "middle eastern"                            = "Asian",
  "black and white"                           = "Multiracial",
  "mixed white/ native"                       = "Multiracial",
  "mixed (european & hispanic)"               = "Multiracial",
  "mixed white and black"                     = "Multiracial",
  "asian and white"                           = "Multiracial",
  "half white/half asian"                     = "Multiracial",
  "bi-racial"                                 = "Multiracial",
  "mixed race; white and black"               = "Multiracial",
  "hispanic and white"                        = "Other",
  "black/white/puerto rican"                  = "Other",
  "hispanic"                                  = "Other",
  "hispanic (puerto rico)"                    = "Other",
  "mediterranean"                             = "Other",
  "biracial-black/white"                      = "Multiracial"
)

age_levels <- c("0-4 months", "5-12 months", "1-3 years", "4-6 years")

data <- raw %>%
  mutate(
    DOB = parse_dob(DOB),

    Race_group = unname(race_map[tolower(str_trim(as.character(Race)))]),
    Race_group = factor(replace_na(Race_group, "Other")),

    Age_at_diagnosis = case_when(
      str_detect(Age_at_craniosynostosis_diagnosis, "0-4 mo")  ~ "0-4 months",
      str_detect(Age_at_craniosynostosis_diagnosis, "5-12 mo") ~ "5-12 months",
      str_detect(Age_at_craniosynostosis_diagnosis, "1-3 y")   ~ "1-3 years",
      str_detect(Age_at_craniosynostosis_diagnosis, "4-6 y")   ~ "4-6 years",
      TRUE ~ NA_character_
    ),
    Age_at_diagnosis = factor(Age_at_diagnosis, levels = age_levels),

    # Hospitalization year: take the 4-digit year if there is one,
    # otherwise a 2-digit year written like '17. Other answers
    # (e.g. "3 months") don't give a year, so they stay NA.
    Hospitalization_year = coalesce(
      as.integer(str_extract(Hospitalization_years, "(19|20)\\d{2}")),
      as.integer(str_extract(Hospitalization_years, "(?<=['‘’])\\d{2}")) + 2000L
    ),

    Insurance_group = case_when(
      str_detect(Insurance_status, regex("Private",  ignore_case = TRUE)) ~ "Private insurance",
      str_detect(Insurance_status, regex("Medicaid", ignore_case = TRUE)) ~ "Medicaid",
      is.na(Insurance_status) ~ NA_character_,
      TRUE ~ "Other"
    )
  ) %>%
  mutate(across(c(Gender, US_state, Craniosynostosis_diagnosis, Birth_type,
                  Genetic_testing, Risk_factors, Insights_causes,
                  Cognitive_impact, Speech_and_language_impact,
                  Speech_and_language_challenges, Quality_of_life),
                as.factor))

# Check: every original race answer should land in the right group.
# Any answer not listed in race_map falls into "Other", so add it above if needed.
print(table(data$Race, data$Race_group, useNA = "ifany"))


# ---- 3. Turn multi-select answers into 0/1 columns ---------------------------

data <- data %>%
  mutate(
    # Craniosynostosis types
    Metopic          = flag(Types_of_craniosynostosis, "Metopic"),
    Sagittal         = flag(Types_of_craniosynostosis, "Sagittal"),
    Coronal          = flag(Types_of_craniosynostosis, "(?<!Bi)Coronal Craniosynostosis"),
    Lambdoid         = flag(Types_of_craniosynostosis, "Lambdoid"),
    Frontosphenoidal = flag(Types_of_craniosynostosis, "Frontosphenoidal"),
    Bicoronal        = flag(Types_of_craniosynostosis, "Bicoronal"),
    Multiple         = flag(Types_of_craniosynostosis, "Multiple|Mercedes|Double Suture|rest of her sutures"),

    # Initial symptoms
    Sym_no_soft_spot   = flag(Initial_symptoms, "No \"soft spot\""),
    Sym_raised_ridge   = flag(Initial_symptoms, "raised hard ridge"),
    Sym_unusual_shape  = flag(Initial_symptoms, "Unusual head shape"),
    Sym_slow_growth    = flag(Initial_symptoms, "Slow or no increase"),
    Sym_other          = as.integer(Sym_no_soft_spot + Sym_raised_ridge +
                                      Sym_unusual_shape + Sym_slow_growth == 0),

    # Diagnosis methods
    Dx_CT         = flag(Primary_method_used_for_diagnosis, "\\bCT\\b"),
    Dx_Xray       = flag(Primary_method_used_for_diagnosis, "X-ray"),
    Dx_Physical   = flag(Primary_method_used_for_diagnosis, "Physical"),
    Dx_MRI        = flag(Primary_method_used_for_diagnosis, "MRI"),
    Dx_Ultrasound = flag(Primary_method_used_for_diagnosis, "Ultra ?sound"),
    Dx_Genetic    = flag(Primary_method_used_for_diagnosis, "Genetic Testing"),
    Dx_Surgery    = flag(Primary_method_used_for_diagnosis, "Surgery"),
    Dx_3D         = flag(Primary_method_used_for_diagnosis, "3 ?D imaging"),

    # Treatments
    Tx_Endoscopic = flag(Types_of_treatments, "Endo|spring"),
    Tx_Helmet     = flag(Types_of_treatments, "Helmet|Cranial Molding"),
    Tx_Monitoring = flag(Types_of_treatments, "No treatment, only monitoring"),
    Tx_Open       = flag(Types_of_treatments, "Cranial Surgery|CVR|FOA|vault")
  )

type_cols   <- c("Metopic", "Sagittal", "Coronal", "Lambdoid",
                 "Frontosphenoidal", "Bicoronal", "Multiple")
type_labels <- paste(type_cols, "Synostosis")

# One main type per child: a child with more than one type ticked,
# or who reported multiple sutures, is counted as "Multiple".
data <- data %>%
  mutate(
    n_types = rowSums(across(all_of(type_cols))),
    Main_type = case_when(
      Multiple == 1 | n_types > 1 ~ "Multiple Synostosis",
      Metopic == 1          ~ "Metopic Synostosis",
      Sagittal == 1         ~ "Sagittal Synostosis",
      Coronal == 1          ~ "Coronal Synostosis",
      Lambdoid == 1         ~ "Lambdoid Synostosis",
      Frontosphenoidal == 1 ~ "Frontosphenoidal Synostosis",
      Bicoronal == 1        ~ "Bicoronal Synostosis",
      TRUE ~ NA_character_
    )
  )

# Analysis sample: children diagnosed with craniosynostosis.
# (Filtered copies get their own names so `data` is never overwritten.)
diagnosed <- data %>% filter(Craniosynostosis_diagnosis != "No")
cat("Diagnosed children:", nrow(diagnosed), "\n")


# ---- 4. Descriptive charts --------------------------------------------------

# Helper: count 0/1 columns and turn them into a tidy table
count_flags <- function(df, cols, labels) {
  tibble(Category = labels,
         Count    = sapply(cols, function(c) sum(df[[c]], na.rm = TRUE))) %>%
    mutate(Percent_of_children = 100 * Count / nrow(df))
}

# Helper: horizontal bar chart with % labels
flag_bar <- function(tbl, title, x_lab = "") {
  ggplot(tbl, aes(x = reorder(Category, Count), y = Count)) +
    geom_col(fill = bar_fill) +
    geom_text(aes(label = sprintf("%.1f%%", Percent_of_children)),
              hjust = -0.1, size = 3.8, fontface = "bold") +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = title, x = x_lab, y = "Number of children") +
    theme_capstone()
}

# 4.1 Initial symptoms
symptoms <- count_flags(
  diagnosed,
  c("Sym_no_soft_spot", "Sym_raised_ridge", "Sym_unusual_shape",
    "Sym_slow_growth", "Sym_other"),
  c("No soft spot (fontanelle)", "Raised hard ridge", "Unusual head shape",
    "Slow or no head growth", "Other symptoms")
)
save_chart(flag_bar(symptoms, "Initial Symptoms"), "01_initial_symptoms")

# 4.2 Gender among diagnosed children
gender_plot <- ggplot(diagnosed, aes(x = Gender)) +
  geom_bar(fill = bar_fill, width = 0.5) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.4, size = 5) +
  labs(title = "Diagnosed Children by Gender", x = NULL, y = "Number of children") +
  theme_capstone()
save_chart(gender_plot, "02_gender")

# 4.3 Age at diagnosis
age_plot <- diagnosed %>%
  filter(!is.na(Age_at_diagnosis)) %>%
  ggplot(aes(x = Age_at_diagnosis)) +
  geom_bar(fill = bar_fill) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.4) +
  labs(title = "Age at Diagnosis", x = "Age group", y = "Number of children") +
  theme_capstone()
save_chart(age_plot, "03_age_at_diagnosis")

# 4.4 State and race
state_plot <- diagnosed %>%
  count(US_state) %>%
  mutate(Percent = 100 * n / sum(n)) %>%
  ggplot(aes(x = reorder(US_state, n), y = n)) +
  geom_col(fill = bar_fill) +
  geom_text(aes(label = sprintf("%.1f%%", Percent)), hjust = -0.1, size = 3) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Respondents by State of Birth", x = NULL, y = "Number of children") +
  theme_capstone()
save_chart(state_plot, "04_state", height = 9)

race_plot <- diagnosed %>%
  count(Race_group) %>%
  ggplot(aes(x = reorder(Race_group, n), y = n)) +
  geom_col(fill = bar_fill) +
  geom_text(aes(label = n), hjust = -0.2, fontface = "bold") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Respondents by Race", x = NULL, y = "Number of children") +
  theme_capstone()
save_chart(race_plot, "05_race")

# 4.5 Craniosynostosis types (a child can have more than one type,
#     so the percentages can add up to more than 100%)
types <- count_flags(diagnosed, type_cols, type_labels)
print(types)
save_chart(flag_bar(types, "Craniosynostosis Types"), "06_types")

# 4.6 Types by age at diagnosis
type_age_plot <- diagnosed %>%
  filter(!is.na(Age_at_diagnosis)) %>%
  group_by(Age_at_diagnosis) %>%
  summarise(across(all_of(type_cols), sum), .groups = "drop") %>%
  pivot_longer(-Age_at_diagnosis, names_to = "Type", values_to = "Count") %>%
  ggplot(aes(x = Age_at_diagnosis, y = Count, fill = Type)) +
  geom_col(position = position_dodge(width = 0.9)) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Craniosynostosis Types by Age at Diagnosis",
       x = "Age at diagnosis", y = "Number of children") +
  theme_capstone()
save_chart(type_age_plot, "07_types_by_age", width = 10)

# 4.7 Diagnosis methods
methods <- count_flags(
  diagnosed,
  c("Dx_CT", "Dx_Xray", "Dx_Physical", "Dx_MRI", "Dx_Ultrasound",
    "Dx_Genetic", "Dx_Surgery", "Dx_3D"),
  c("CT scan", "X-ray", "Physical exam", "MRI", "Ultrasound",
    "Genetic testing", "Surgical evaluation", "3D imaging")
)
save_chart(flag_bar(methods, "Diagnosis Methods"), "08_diagnosis_methods")

# 4.8 Treatments (% of children who received each one)
treatments <- count_flags(
  diagnosed,
  c("Tx_Open", "Tx_Endoscopic", "Tx_Helmet", "Tx_Monitoring"),
  c("Open surgery", "Endoscopic surgery", "Helmet therapy", "Monitoring only")
)
print(treatments)
save_chart(flag_bar(treatments, "Treatments Received"), "09_treatments")

# 4.9 Treatment by age at surgery
surgery_data <- diagnosed %>% filter(!is.na(Age_cranial_surgery_performed))

tx_age_plot <- surgery_data %>%
  group_by(Age_cranial_surgery_performed) %>%
  summarise(`Open surgery`       = sum(Tx_Open),
            `Endoscopic surgery` = sum(Tx_Endoscopic),
            `Helmet therapy`     = sum(Tx_Helmet), .groups = "drop") %>%
  pivot_longer(-Age_cranial_surgery_performed,
               names_to = "Treatment", values_to = "Count") %>%
  ggplot(aes(x = Age_cranial_surgery_performed, y = Count, fill = Treatment)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = c("#FBB4AE", "#B3CDE3", "#CCEBC5")) +
  labs(title = "Treatment by Age at Surgery", x = "Age at surgery", y = "Number of children") +
  theme_capstone()
save_chart(tx_age_plot, "10_treatment_by_age", width = 9)

# 4.10 Outcomes within each treatment (% of children who had that treatment)
outcome_by_tx <- diagnosed %>%
  filter(!is.na(Outcomes)) %>%
  pivot_longer(c(Tx_Open, Tx_Endoscopic, Tx_Helmet),
               names_to = "Treatment", values_to = "Received") %>%
  filter(Received == 1) %>%
  mutate(Treatment = recode(Treatment, Tx_Open = "Open surgery",
                            Tx_Endoscopic = "Endoscopic surgery",
                            Tx_Helmet = "Helmet therapy")) %>%
  count(Treatment, Outcomes) %>%
  group_by(Treatment) %>%
  mutate(Percent = 100 * n / sum(n)) %>%
  ungroup()
print(outcome_by_tx)

outcome_plot <- ggplot(outcome_by_tx, aes(x = Treatment, y = Percent, fill = Outcomes)) +
  geom_col(position = "stack", width = 0.6) +
  scale_fill_brewer(palette = "Pastel1") +
  coord_flip() +
  labs(title = "Outcomes by Treatment", x = NULL, y = "% of children with that treatment") +
  theme_capstone()
save_chart(outcome_plot, "11_outcomes_by_treatment")

# 4.11 Quality of life and satisfaction
quality_plot <- diagnosed %>%
  filter(!is.na(Quality_of_life)) %>%
  ggplot(aes(x = fct_infreq(Quality_of_life))) +
  geom_bar(fill = bar_fill) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.4) +
  labs(title = "Quality of Life After Treatment", x = NULL, y = "Number of children") +
  theme_capstone()
save_chart(quality_plot, "12_quality_of_life")

satisfaction <- diagnosed %>%
  filter(!is.na(Satisfactory_level)) %>%
  mutate(Level = factor(Satisfactory_level, levels = c("5", "4", "3", "2", "1"),
                        labels = c("5 - Very satisfied", "4", "3", "2", "1 - Not satisfied")))
print(round(100 * prop.table(table(satisfaction$Level)), 1))

satisfaction_plot <- ggplot(satisfaction, aes(x = Level)) +
  geom_bar(fill = bar_fill) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.4) +
  labs(title = "Satisfaction With Treatment Results", x = NULL, y = "Number of children") +
  theme_capstone()
save_chart(satisfaction_plot, "13_satisfaction")

# 4.12 Other summaries (percentages of diagnosed children)
pct <- function(x) round(100 * prop.table(table(x, useNA = "ifany")), 1)
pct(diagnosed$Insurance_group)
pct(diagnosed$Genetic_testing)
pct(diagnosed$Birth_type)
pct(diagnosed$Cognitive_impact)
pct(diagnosed$Speech_and_language_impact)
table(diagnosed$Hospitalization_year, useNA = "ifany")


# ---- 5. Statistical tests ---------------------------------------------------
# Fisher's exact test for each craniosynostosis type against one variable.
# We run 7 tests per question, so we also report a Bonferroni-adjusted
# p-value to reduce the chance of false positives.

fisher_by_type <- function(df, outcome) {
  df <- df %>% filter(!is.na(.data[[outcome]]))
  tibble(
    Type = type_labels,
    p_value = sapply(type_cols, function(col) {
      tab <- table(df[[col]], df[[outcome]])
      if (nrow(tab) < 2 || ncol(tab) < 2) return(NA_real_)  # test not possible
      fisher.test(tab, workspace = 2e7)$p.value
    })
  ) %>%
    mutate(p_bonferroni = p.adjust(p_value, method = "bonferroni"),
           significant_0.05 = p_value < 0.05,
           significant_adjusted = p_bonferroni < 0.05)
}

results_gender    <- fisher_by_type(diagnosed, "Gender")
results_age       <- fisher_by_type(diagnosed, "Age_at_diagnosis")
results_cognitive <- fisher_by_type(diagnosed, "Cognitive_impact")
results_speech    <- fisher_by_type(diagnosed, "Speech_and_language_impact")

cat("\n## Type vs. gender\n");            print(kable(results_gender, digits = 4))
cat("\n## Type vs. age at diagnosis\n");  print(kable(results_age, digits = 4))
cat("\n## Type vs. cognitive impact\n");  print(kable(results_cognitive, digits = 4))
cat("\n## Type vs. speech/language\n");   print(kable(results_speech, digits = 4))

# Age at surgery vs. outcome
tab_age_outcome <- table(surgery_data$Age_cranial_surgery_performed, surgery_data$Outcomes)
print(fisher.test(tab_age_outcome, workspace = 2e7))

# Age at diagnosis vs. cognitive and speech impact
print(fisher.test(table(diagnosed$Cognitive_impact, diagnosed$Age_at_diagnosis),
                  workspace = 2e7))
print(fisher.test(table(diagnosed$Speech_and_language_impact, diagnosed$Age_at_diagnosis),
                  workspace = 2e7))
