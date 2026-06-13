clean_airq <- function(df, city_name) {
  df %>%
    rename_with(trimws) %>%
    mutate(
      across(c(pm25, pm10, o3, no2, so2, co),
             ~ as.numeric(na_if(trimws(as.character(.x)), ""))),
      city      = city_name,
      city_type = case_when(
        city_name %in% c("Busan", "Incheon") ~ "Coastal",
        city_name %in% c("Seoul", "Daegu")   ~ "Inland"
      )
    ) %>%
    select(date, city, city_type, pm25, pm10, o3, no2, so2, co)
}
```

```{r}
seoul_clean <- clean_airq(seoul_air_quality, "Seoul")
busan_clean <- clean_airq(busan_air_quality, "Busan")
daegu_clean <- clean_airq(daegu_air_quality, "Daegu")
incheon_clean <- clean_airq(incheon_air_quality, "Incheon")
```

```{r}
airq <- bind_rows(seoul_clean, busan_clean, daegu_clean, incheon_clean) %>%
  mutate(year = year(date)) %>% # Added variable for easier analysis in future analysis techniques
  filter(year < 2026) # Filtering out 2026 as it does not have a full year of data
```

```{r}
pollutants <- c("pm25", "pm10", "o3", "no2", "so2", "co")
summary(airq[, pollutants])
# These values are in AQI index numbers, not raw concentration units (ppm); hence, they should be converted later; this varies from pollutant to pollutant
```

```{r}
airq_annual <- airq %>%
  group_by(city, city_type, year) %>%
  summarise(across(all_of(pollutants),
                   ~ mean(.x, na.rm = TRUE),
                   .names = "mean_{.col}"),
            n_days = n(),
            .groups = "drop")
```

```{r}
who_aqi <- c(pm25 = 50, pm10 = 50, o3 = 50, no2 = 50) # AQI Values of Index --> upper bound of Level of Concern: Good

airq_exceed <- airq %>%
  group_by(city, city_type, year) %>%
  summarise(
    exceed_pm25 = sum(pm25 > who_aqi["pm25"], na.rm = TRUE),
    exceed_pm10 = sum(pm10 > who_aqi["pm10"], na.rm = TRUE),
    exceed_o3   = sum(o3   > who_aqi["o3"],   na.rm = TRUE),
    exceed_no2  = sum(no2  > who_aqi["no2"],  na.rm = TRUE),
    .groups = "drop"
  )
```

```{r}
assign_aqi_category <- function(aqi_value) {
  case_when(
    aqi_value <= 50 ~ "Good",
    aqi_value <= 100 ~ "Moderate",
    aqi_value <= 150  ~ "Unhealthy for Sensitive Groups",
    aqi_value <= 200 ~ "Unhealthy",
    aqi_value <= 300 ~ "Very Unhealthy",
    aqi_value  > 300 ~ "Hazardous",
    TRUE ~ NA_character_
  )}

aqi_levels <- c("Good", "Moderate", "Unhealthy for Sensitive Groups", "Unhealthy", "Very Unhealthy", "Hazardous")


airq_cats <- airq %>%
  mutate(across(all_of(pollutants),
                ~ assign_aqi_category(.x),
                .names = "cat_{.col}"))

# Organize how many days, based on year and pollutant, were in each AQI level 
airq_cat_summary <- airq_cats %>%
  pivot_longer(starts_with("cat_"),
               names_to  = "pollutant",
               values_to = "category") %>%
  mutate(
    pollutant = str_remove(pollutant, "cat_"),
    category  = factor(category, levels = aqi_levels, ordered = TRUE)
  ) %>%
  filter(!is.na(category)) %>%          # ← add this line
  group_by(city, year, pollutant, category) %>%
  summarise(days = n(), .groups = "drop")
```

```{r}
airq_overall_mean <- airq_annual %>%
  group_by(city) %>%
  summarise(across(starts_with("mean_"), ~ mean(.x, na.rm = TRUE)),
            .groups = "drop")
```

```{r}
# Cleaning Summary_of_Census_Population
pop_raw <- Summary_of_Census_Population_By_administrative_district_sex_age_20260514092656 %>%
  slice(-1) %>%
  rename(
    division = 1,
    age_raw = 2,
    pop_total = 3,
    pop_male = 4,
    pop_female = 5) %>%
  select(division, age_raw, pop_total, pop_male, pop_female)

exclude <- c("Total", "14 and under", "15 - 64 Years old", "65 Years old", "Mean age", "Median age")

pop_cities <- pop_raw %>%
  filter(
    division %in% c("Seoul", "Busan", "Daegu", "Incheon"),
    !age_raw %in% exclude) %>%
  mutate(
    across(c(pop_total, pop_male, pop_female), 
           ~ as.numeric(gsub(",", "", .x))))
```

```{r}
# Cleaning Demographic Data
pop_grouped <- pop_cities %>%
  mutate(age_group = case_when(
      age_raw %in% c("0-4 Years old",
                     "5-9 Years old",
                     "10-14 Years old") ~ "Children",
      age_raw %in% c("15-19 Years old", "20-24 Years old",
                     "25-29 Years old", "30-34 Years old",
                     "35-39 Years old", "40-44 Years old",
                     "45-49 Years old", "50-54 Years old",
                     "55-59 Years old", "60-64 Years old") ~ "Adults",
      age_raw %in% c("65-69 Years old", "70-74 Years old",
                     "75-79 Years old", "80-84 Years old",
                     "85 Years old & over") ~ "Elderly")) %>%
  rename(city = division)

pop_long <- pop_grouped %>%
  select(city, age_group, pop_male, pop_female) %>%
  pivot_longer(
    cols = c(pop_male, pop_female),
    names_to = "sex",
    values_to = "population") %>%
  mutate(sex = recode(sex,
                      "pop_male" = "Male",
                      "pop_female" = "Female")) %>%
  group_by(city, age_group, sex) %>%
  summarise(population = sum(population, na.rm = TRUE), 
            .groups = "drop")
```

```{r}
total_pop <- pop_long %>%
  summarise(total = sum(population))

pop_total_city <- pop_long %>%
  group_by(city) %>%
  summarise(city_pop = sum(population), .groups = "drop")

# Population weighted concentration
pwc_city <- airq_overall_mean %>%
  left_join(pop_total_city, by = "city") %>%
  mutate(across(starts_with("mean_"),
                ~ (.x * city_pop) / total_pop,
                .names = "pwc_{.col}"))


pwc_demographic <- pop_long %>%
  left_join(airq_overall_mean, by = "city") %>%
  pivot_longer(starts_with("mean_"),
               names_to  = "pollutant",
               values_to = "mean_conc") %>%
  mutate(pollutant = str_remove(pollutant, "mean_")) %>%
  group_by(sex, age_group, pollutant) %>%
  summarise(
    pwc = sum(mean_conc * population) / total_pop,
    .groups = "drop"
  )
