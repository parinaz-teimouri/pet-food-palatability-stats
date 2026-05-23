# Analysis Report: Pet Food Palatability Trials

**Analyst:** Parinaz Teimouri

---

## Executive Summary

This report presents results from a 2x3 factorial feeding trial analyzing the effect of pet species (Dog, Cat) and food formula (Control, New Protein, New Flavour Coating) on palatability outcomes. The dataset contains **500 observations** after cleaning.

**Key finding:** Food formula has a highly significant effect on palatability score (F = 58.32, p = < 0.001, eta-squared = 0.191). **New Flavour Coating** shows the highest palatability (EMM = 7.9), significantly outperforming both other formulas.

---

## 1. Data Overview

| Metric | Value |
|--------|-------|
| Total observations | 500 |
| Dogs | 270 |
| Cats | 230 |
| Formulas | 3 (Control, New Protein, New Flavour Coating) |
| Response variables | palatability_score, time_to_first_bite, consumed_amount_grams |

### Data Quality Issues Resolved

- **Duplicate rows:** 3 exact duplicates removed
- **Outliers:** 2 rows with impossible values removed (palatability > 10, consumption > 200g)
- **Date parsing:** 4 dates unparseable after cleaning, set to NA
- **Missing values imputed:** Group-median (species x formula) for palatability and consumption
- **String cleanup:** Whitespace trimmed, N/A strings converted to proper NA

---

## 2. Statistical Results

### 2.1 Two-Way ANOVA: Palatability Score ~ Species * Formula

```
Anova Table (Type II tests)

Response: palatability_score
                Sum Sq  Df F value    Pr(>F)    
species          33.08   1 22.4200 < 0.001 ***
formula         172.05   2 58.3200 < 0.001 ***
species:formula   9.54   2 3.2300 0.040 *
Residuals       728.66 494                      
```

**Effect sizes (partial eta-squared):**

- Species: eta^2 = 0.047 (small effect)
- Formula: eta^2 = 0.191 (large effect)
- Interaction: eta^2 = 0.013 (small effect)

### 2.2 Assumption Checks

- **Normality (Shapiro-Wilk):** W = 0.9917, p = 0.007 — marginal deviation from normality, but ANOVA is robust to mild violations at this sample size
- **Homogeneity (Levene's):** F = 1.22, p = 0.298 — equal variances assumption satisfied

### 2.3 Post-hoc Tukey HSD: Which Formulas Differ?

| Contrast | Estimate | SE | p-value | Significance |
|----------|----------|-----|---------|--------------|
| Control (A) vs New Protein (B) | -0.88 | 0.134 | < 0.001 | *** |
| Control (A) vs New Flavour (C) | -1.429 | 0.132 | < 0.001 | *** |
| New Protein (B) vs New Flavour (C) | -0.549 | 0.134 | < 0.001 | *** |

**All three formula pairs differ significantly.** The ranking is:

1. **New Flavour Coating** (EMM = 7.9)
2. **New Protein** (EMM = 7.35)
3. **Control** (EMM = 6.47)

### 2.4 Dog vs. Cat: Palatability

- t = -4.425, df = 480.2, p = < 0.001
- Cohen's d = -0.398 (small-to-medium)
- Dogs (mean = 7.5) score higher than cats (mean = 6.96)

### 2.5 Dog vs. Cat: Consumption

- t = -15.283, df = 489.7, p = < 0.001
- Dogs consume 79.9g on average; cats consume 60.1g

### 2.6 Chi-squared: High Palatability × Species

Median split at 7.3. Each pet tests one formula (not a crossover),
so we test whether achieving high palatability is associated with species.

```
     
      High Low
  Cat   93 137
  Dog  152 118
```
- Chi-squared = 11.877, df = 1, p = < 0.001
- Cramer's V = 0.154
- Species and high palatability are **associated** — one species is more likely to score above the median

### 2.7 Pearson Correlation: Age vs. Consumption

- r = -0.02, t = -0.457, p = 0.648
- 95% CI: [-0.108, 0.067]
- Age has **no meaningful correlation** with consumption amount

### 2.8 Correlation Matrix

| Variable | Palatability | Time to Bite | Consumed | Age | Weight |
|----------|-------------|-------------|----------|-----|--------|
| Palatability | 1 | -0.606 | 0.637 | -0.038 | 0.138 |
| Time to Bite | -0.606 | 1 | -0.443 | 0.064 | -0.099 |
| Consumed | 0.637 | -0.443 | 1 | -0.027 | 0.458 |
| Age | -0.038 | 0.064 | -0.027 | 1 | 0.055 |
| Weight | 0.138 | -0.099 | 0.458 | 0.055 | 1 |

Key correlations:
- Palatability and time-to-bite: r = -0.606 (higher scores → faster eating)
- Palatability and consumption: r = 0.637 (higher scores → more eaten)
- Weight and consumption: r = 0.458 (heavier pets eat more)

---

## 3. Visualization Summary

| Figure | Description | File |
|--------|-------------|------|
| Box plot | Palatability by formula with Tukey significance brackets | `palatability_by_formula.png` |
| Bar chart | Mean palatability by species + formula with error bars | `species_comparison.png` |
| Interaction plot | Formula x Species interaction pattern | `interaction_plot.png` |
| Correlation heatmap | Relationships among numeric variables | `correlation_heatmap.png` |
| Violin plot | Full distribution shape by formula + species | `violin_plot.png` |

---

## 4. Conclusions

1. **New Flavour Coating is the most palatable formulation** — it scores 1.43 points higher than the Control on a 10-point scale. This is the strongest candidate for further development.

2. **Cats are more discriminating than dogs** — the significant interaction (p = 0.040) and small-to-medium species effect (d = -0.398) suggest cats respond more strongly to formula differences.

3. **The interaction is a small effect** — with eta-squared = 0.013, species accounts for only ~1.3% of variance in the formula effect. Formulas work broadly the same across species, just with different baselines.

4. **Age and weight are not confounds** — neither correlates meaningfully with palatability, supporting generalizability across pet demographics.

---

## 5. Limitations & Recommendations

### Limitations
- Synthetic data — results are illustrative, not from actual Mars trials
- Single-trial design — no repeated measures or crossover to control for individual variation
- No brand familiarity covariate — pets may prefer what they know
- Shapiro-Wilk marginal (p = 0.007) — ANOVA is robust at this sample size (n = 500)

### Recommendations
- Run a **crossover trial** with the same pets testing all three formulas
- Include **brand familiarity** and **prior diet** as covariates
- Extend to **larger sample sizes** for greater statistical power
- Consider **mixed-effects models** for repeated measures designs

---

## Reproducibility

This analysis is fully reproducible. Clone the repository and run:

```r
source("requirements.R")
source("generate_data.R")
source("scripts/01_data_quality.R")
source("scripts/02_data_wrangling.R")
source("scripts/03_statistical_analysis.R")
source("scripts/04_visualization.R")
source("scripts/05_export_to_lake.R")
source("scripts/06_generate_report.R")
```

All random seeds are fixed (`set.seed(42)`) for deterministic output.
