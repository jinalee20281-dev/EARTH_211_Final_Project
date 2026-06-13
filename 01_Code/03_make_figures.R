sc <- for (c in c("Seoul", "Busan", "Daegu", "Incheon")) {
  city_data <- airq %>%
    filter(city == c) %>%
    select(all_of(pollutants)) %>%
    drop_na()
  corr_mat <- cor(city_data, method = "spearman")
  corrplot(
    corr_mat,
    method = "color",
    type = "upper",
    addCoef.col = "black",
    number.cex = 0.75,
    tl.cex = 0.9,
    title = paste("Spearman Correlations —", c),
    mar = c(0, 0, 1, 0))}

ggsave("sp_correlation.png")

airq %>%
  pivot_longer(all_of(pollutants),
               names_to  = "pollutant",
               values_to = "aqi") %>%
  ggplot(aes(x = city, y = aqi, fill = city_type)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.1, fill = "pink", outlier.shape = NA) +
  facet_wrap(~ pollutant, scales = "free_y") +
  labs(
    title = "Distribution of Daily AQI Values by City and Pollutant",
    x = NULL,
    y = "AQI",
    fill = "City Type")

ggsave("violin_plot.png")

airq_exceed %>%
  pivot_longer(starts_with("exceed_"),
               names_to  = "pollutant",
               values_to = "days") %>%
  mutate(pollutant = str_remove(pollutant, "exceed_") %>% toupper()) %>%
  ggplot(aes(x = year, y = days, color = city, linetype = city_type)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  facet_wrap(~ pollutant, scales = "free_y") +
  scale_x_continuous(breaks = 2014:2025) +
  labs(
    title    = "Days per Year Exceeding WHO AQI Threshold (AQI > 50) by City",
    x        = NULL,
    y        = "Number of Days",
    color    = "City",
    linetype = "City Type")

ggsave("airq_exceed_graph.png")
