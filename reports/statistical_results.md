# Statistical Analysis Results

Dataset: `data/processed/feeding_trials_clean.csv` (500 observations)

---

## 1. Two-Way ANOVA: Palatability Score ~ Species * Formula

```
Anova Table (Type II tests)

Response: palatability_score
                Sum Sq  Df F value    Pr(>F)    
species          33.08   1 22.4250 2.859e-06 ***
formula         172.05   2 58.3229 < 2.2e-16 ***
species:formula   9.54   2  3.2333   0.04026 *  
Residuals       728.66 494                      
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

**Effect sizes (eta-squared):**

- Species: eta^2 = 0.047
- Formula: eta^2 = 0.191
- Interaction: eta^2 = 0.013

## 2. Assumption Checks

- **Normality (Shapiro-Wilk):** W = 0.9917, p = 0.007
- **Homogeneity (Levene's):** F = 1.22, p = 0.298

## 3. Post-hoc Tukey HSD (Formula Comparisons)

```
 contrast estimate    SE  df t.ratio p.value
 A - B      -0.880 0.134 494  -6.555 <0.0001
 A - C      -1.429 0.132 494 -10.788 <0.0001
 B - C      -0.549 0.134 494  -4.087  0.0002

Results are averaged over the levels of: species 
P value adjustment: tukey method for comparing a family of 3 estimates 
```

**Estimated marginal means:**

|formula | emmean|   SE|  df| lower.CL| upper.CL|
|:-------|------:|----:|---:|--------:|--------:|
|A       |   6.47| 0.09| 494|     6.28|     6.65|
|B       |   7.35| 0.10| 494|     7.16|     7.53|
|C       |   7.90| 0.09| 494|     7.71|     8.08|

## 4. Independent t-test: Dog vs Cat (Palatability)

- t = -4.425, df = 480.2, p = < 0.001
- Cohen's d = -0.398

## 5. Welch's t-test: Dog vs Cat (Consumption)

- t = -15.283, df = 489.7, p = < 0.001

## 6. Chi-squared: High Palatability × Species

Median split at 7.3. Each pet tests one formula (not a crossover),
so we test whether achieving high palatability is associated with species.

```
     
      High Low
  Cat   93 137
  Dog  152 118
```
- Chi-sq = 11.877, df = 1, p = < 0.001
- Cramer's V = 0.154

## 7. Pearson Correlation: Age vs. Consumption

- r = -0.02, t = -0.457, p = 0.648
- 95% CI: [-0.108, 0.067]

## 8. Correlation Matrix

```
                      palatability_score time_to_first_bite
palatability_score                 1.000             -0.606
time_to_first_bite                -0.606              1.000
consumed_amount_grams              0.637             -0.443
age_months                        -0.038              0.064
weight_kg                          0.138             -0.099
                      consumed_amount_grams age_months weight_kg
palatability_score                    0.637     -0.038     0.138
time_to_first_bite                   -0.443      0.064    -0.099
consumed_amount_grams                 1.000     -0.027     0.458
age_months                           -0.027      1.000     0.055
weight_kg                             0.458      0.055     1.000
```
