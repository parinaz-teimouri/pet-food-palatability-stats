# Data Quality Report

Generated from: `data/raw/feeding_trials.csv`
Total rows: **505** | Total columns: **14**

## Missing Values

| Column | Missing | % |
|--------|---------|---|
| notes | 481 | 95.2% |
| weight_kg | 41 | 8.1% |
| palatability_score | 41 | 8.1% |
| consumed_amount_grams | 41 | 8.1% |
| trial_date | 4 | 0.8% |

## Duplicates

- **Exact duplicate rows:** 6
- **Duplicate pet_id + formula:** 6 rows

## Outliers (outside valid ranges)

- palatability_score: values outside [1, 10]
- consumed_amount_grams: values outside [5, 200]
- time_to_first_bite: values outside [1, 60]

## Type & Format Issues

- Date format inconsistencies detected in `trial_date`
- String whitespace issues in categorical columns
- N/A strings present instead of proper NA values

## Summary Statistics

```
   age_months    weight_kg     palatability_score time_to_first_bite
 Min.   :  6   Min.   : 3.00   Min.   : 0.000     Min.   : 2.00     
 1st Qu.: 35   1st Qu.: 4.90   1st Qu.: 6.300     1st Qu.: 7.60     
 Median : 63   Median : 6.60   Median : 7.300     Median :11.70     
 Mean   : 64   Mean   :13.41   Mean   : 7.244     Mean   :11.87     
 3rd Qu.: 94   3rd Qu.:21.70   3rd Qu.: 8.200     3rd Qu.:15.60     
 Max.   :120   Max.   :39.90   Max.   :15.000     Max.   :60.00     
               NAs    :41      NAs    :41                           
 consumed_amount_grams   row_number 
 Min.   :  5.00        Min.   :  1  
 1st Qu.: 59.10        1st Qu.:127  
 Median : 71.10        Median :253  
 Mean   : 71.80        Mean   :253  
 3rd Qu.: 82.67        3rd Qu.:379  
 Max.   :500.00        Max.   :505  
 NAs    :41                         
```
