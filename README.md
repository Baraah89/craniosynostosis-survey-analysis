# Craniosynostosis in U.S. Infants: A Parent-Reported Survey Analysis

**Capstone project, M.S. Data Analytics, University of Houston–Downtown (Fall 2023)**
Author: Baraah Alshannaq · Advisor: Prof. Benjamin Soibam

## Overview

Craniosynostosis is a birth defect where an infant's skull bones fuse too early. It affects about 1 in 2,500 U.S. births. Most published research comes from clinical records. This project looks at the condition from the families' side: how and when children were diagnosed, which treatments they received, and how they are doing afterward.

I designed the survey, got ethics approval, collected the data, and ran the full analysis in R.

## Key question

Does the **type** of craniosynostosis relate to **age at diagnosis**, **gender**, **cognitive impact**, and **speech and language development**?

## Data

| | |
|---|---|
| **Source** | Original survey of parents and caregivers of infants diagnosed with craniosynostosis |
| **Collection** | Google Forms, shared in five online support communities (Cranio Kids, Cranio Care Bears, Craniosynostosis Metopic Q&A, CAPPSKIDS.org, and others) |
| **Ethics** | Approved by the UHD Human Subjects Committee (IRB). All participants gave informed consent. |
| **Size** | 400 responses × 32 variables |
| **Variables** | Demographics (birth date, gender, race, state), diagnosis and symptoms, treatment and insurance, cognitive and speech outcomes, quality of life, satisfaction |

> **Privacy note:** The raw survey data contains health information about children and is not published in this repository. The code and a data dictionary are provided instead.

## Methods

1. **Data cleaning (R):** standardized free-text answers, recoded multi-select questions into indicator columns, derived age at diagnosis from birth and diagnosis dates, and handled missing values.
2. **Exploratory analysis:** distributions by type, gender, age, state, and race.
3. **Statistical testing:** Fisher's exact tests (suited to small cell counts) to test links between craniosynostosis type and gender, age at diagnosis, cognitive impact, and speech/language impact.
4. **Visualization:** charts of type distribution, diagnosis age, treatment by age group, and outcomes.

## Key findings

- **Sagittal synostosis was the most common type (55.2%)**, followed by metopic (22.5%) and coronal (18.5%).
- **Gender:** significant associations for **sagittal and coronal** types; no significant link for other types.
- **Age at diagnosis:** most children were diagnosed at **0–4 months**. Age was significantly associated with sagittal, lambdoid, frontosphenoidal, and multiple-suture types.
- **Treatment:** open surgery was most common (46%) and more frequent after 6 months of age. Endoscopic surgery (26%) and helmet therapy (28%) were mostly used for younger infants.
- **Development:** 24% of parents reported a cognitive impact and 29% reported speech or language delays. No type reached significance at p < 0.05, but sagittal (cognitive) and multiple-suture (speech) types showed trends worth studying with a larger sample.
- **Outcomes:** most parents rated their child's quality of life as excellent, and **66% were very satisfied** with treatment results (2% not satisfied).

## Limitations

- **Self-selected sample:** respondents came from online support groups, so the sample over-represents Texas and White families. Results describe this group, not national prevalence.
- **Few undiagnosed respondents:** with only 2 respondents without a diagnosis, the data cannot test whether family history is a risk factor.
- **Parent-reported outcomes:** cognitive and speech impacts are based on parents' reports, not clinical assessments.

## Future work

- Study syndromes associated with craniosynostosis
- Follow long-term recovery after surgery
- Analyze surgery costs
- Look at environmental, maternal, and prenatal factors
- Evaluate genetic testing for early detection

## Tools

**R** for cleaning, analysis, statistical testing, and visualization · **Google Forms** for data collection · **PowerPoint** for the final presentation

## Contact

Baraah Alshannaq · [https://www.linkedin.com/in/baraah-alshannaq-43775a111/] · baraah.shannaq89@gmail.com
