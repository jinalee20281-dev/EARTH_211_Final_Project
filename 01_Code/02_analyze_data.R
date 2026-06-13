```{r}
kw_pm25 <- kruskal.test(pm25 ~ city, data = airq)
kw_pm10 <- kruskal.test(pm10 ~ city, data = airq)
kw_o3   <- kruskal.test(o3   ~ city, data = airq)
kw_no2  <- kruskal.test(no2  ~ city, data = airq)
kw_so2  <- kruskal.test(so2  ~ city, data = airq)
kw_co   <- kruskal.test(co   ~ city, data = airq)

library(broom)
kw_table <- bind_rows(
  "PM2.5" = tidy(kw_pm25),
  "PM10" = tidy(kw_pm10),
  "O3" = tidy(kw_o3),
  "NO2" = tidy(kw_no2),
  "SO2" = tidy(kw_so2),
  "CO" = tidy(kw_co),
  .id = "Pollutant")

print(kw_table)
```

```{r}
pollutant_list <- airq[, c("pm25", "pm10", "o3", "no2", "so2", "co")]

dunn_table <- map_dfr(names(pollutant_list), function(pol) {
  res <- dunn.test(airq[[pol]], airq$city, method = "bonferroni", list = TRUE)
  tibble(
    Pollutant = pol,
    Comparison = res$comparisons,
    Z_Stat = res$Z,
    P_Bonferroni = res$P.adjusted)})

print(dunn_table)
```


```{r}
library(broom)

mw_table <- bind_rows(
  "PM2.5" = tidy(mw_pm25),
  "PM10"  = tidy(mw_pm10),
  "O3"    = tidy(mw_o3),
  "NO2"   = tidy(mw_no2),
  "SO2"   = tidy(mw_so2),
  "CO"    = tidy(mw_co),
  .id = "Pollutant")

print(mw_table)
```

```{r}
mk_list <- list(
  Seoul = list(PM2.5 = mk_seoul_pm25, PM10 = mk_seoul_pm10, O3 = mk_seoul_o3, NO2 = mk_seoul_no2, SO2 = mk_seoul_so2, CO = mk_seoul_co),
  Busan = list(PM2.5 = mk_busan_pm25, PM10 = mk_busan_pm10, O3 = mk_busan_o3, NO2 = mk_busan_no2, SO2 = mk_busan_so2, CO = mk_busan_co),
  Daegu = list(PM2.5 = mk_daegu_pm25, PM10 = mk_daegu_pm10, O3 = mk_daegu_o3, NO2 = mk_daegu_no2, SO2 = mk_daegu_so2, CO = mk_daegu_co),
  Incheon = list(PM2.5 = mk_incheon_pm25, PM10 = mk_incheon_pm10, O3 = mk_incheon_o3, NO2 = mk_incheon_no2, SO2 = mk_incheon_so2, CO = mk_incheon_co))

rows <- list()
for (city in names(mk_list)) {
  for (pollutant in names(mk_list[[city]])) {
    test_obj <- mk_list[[city]][[pollutant]]
    rows[[length(rows) + 1]] <- data.frame(
      City        = city,
      Pollutant   = pollutant,
      Tau         = test_obj$estimates["tau"],
      Z_Score     = test_obj$statistic["z"],
      P_Value     = test_obj$p.value,
      row.names   = NULL)}}

mk_table <- do.call(rbind, rows)
print(mk_table)
```

```{r}
lm_list <- list(
  Seoul = list(PM2.5 = lm_seoul_pm25, PM10 = lm_seoul_pm10, O3 = lm_seoul_o3, NO2 = lm_seoul_no2, SO2 = lm_seoul_so2, CO = lm_seoul_co),
  Busan = list(PM2.5 = lm_busan_pm25, PM10 = lm_busan_pm10, O3 = lm_busan_o3, NO2 = lm_busan_no2, SO2 = lm_busan_so2, CO = lm_busan_co),
  Daegu = list(PM2.5 = lm_daegu_pm25, PM10 = lm_daegu_pm10, O3 = lm_daegu_o3, NO2 = lm_daegu_no2, SO2 = lm_daegu_so2, CO = lm_daegu_co),
  Incheon = list(PM2.5 = lm_incheon_pm25, PM10 = lm_incheon_pm10, O3 = lm_incheon_o3, NO2 = lm_incheon_no2, SO2 = lm_incheon_so2, CO = lm_incheon_co))

lm_table <- bind_rows(
  lapply(names(lm_list), function(city) {
    bind_rows(
      lapply(names(lm_list[[city]]), function(pollutant) {
        model <- lm_list[[city]][[pollutant]]
        coef_stats <- tidy(model) %>% filter(term == "year")
        model_stats <- glance(model)
        tibble(
          City = city,
          Pollutant = pollutant,
          Slope = coef_stats$estimate,
          Std_Error = coef_stats$std.error,
          P_Value = coef_stats$p.value,
          R_Squared = model_stats$r.squared)}))}))

print(lm_table)
