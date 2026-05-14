# EARTH_211_Final_Project
**Research Questions**
1. To what extent does the concentration of blood lead (Pb) vary globally, and how do effects differ for children and adults in low-income, lower-middle-income, upper-middle-income, and high-income countries?
2. To what extent do the concentrations of criteria air pollutants (PM₂.₅, PM₁₀, O₃, CO, NO₂, SO₂) vary between major South Korean cities, and how do coastal (Busan & Incheon) versus inland urban areas (Seoul & Daegu) disproportionately expose the female and male populations, as well as the children, adult, and elderly populations?

**Information for Collected Data**
  For research question 1, all data - mean blood lead concentration in adults, children, and World Bank income groups - are from Our World in Data (https://ourworldindata.org/). The uploaded files include the relevant information for all countries available on Our World in Data (Children: 34 countries; Adults: 37 countries; Income: 226 countries). The data on children and adults were last updated in 2019, while the income groups were last updated in 2024, but go back to 1987. 
  The main variables used for the mean blood lead concentration in adults and children are age group, concentration (µg/dL), year, entity (country name), and code (country name abbreviation). The main variables for the World Bank income groups are entity (country name), code (country name abbreviation), and the World Bank's income classification. 
  The file format for all data sets is CSV. 

  For research question 2, air quality data for Busan, Daegu, Incheon, and Seoul are from the World Air Quality Historical Database (https://aqicn.org/historical/). The demographic data (Summary of Census Population) is from the KOrean Statistical Information Service (KOSIS), South Korea's national statistical portal. The uploaded files include concentrations for each of the criteria air pollutants (PM₂.₅, PM₁₀, O₃, CO, NO₂, SO₂). The air quality data for the 4 researched cities span from 2014 to 2026. The demographic data is from 2010.
  The main variables used for the air quality data are date, PM₂.₅ and PM₁₀ in µg/m³, and O₃, CO, NO₂, and SO₂ in ppm. The main variables for the demographic data are administrative divisions (eup, myeon, dong), age ranges, year, and population, which is separated by sex.
  The file format for all data sets is CSV.

**Preliminary Research Method**
  The research question that I will be writing a preliminary research method for is Research Question 2. 
Data Cleaning:
1. Use as.Date() to convert dates to values to call data more easily for the air quality csv
2. Filter the 4 administrative divisions for this research project in the air quality csv, and change to long format (rename columns)
3. Stack all four demographic information into one data frame with bind_rows() to make new df
4. Make city_type variable (inland vs coastal) for each city in the new df
5. Delete Row 0 in the population csv, as it contains irrelevant data, and Row 1 contains the actual variable names
6. Add different age groups together to create children (0-18), adults (18-65), and elderly (65+) groups from the population csv
7. Pivot new df to long format

Compared Variables:
Outcome variables - six continuous daily concentrations: PM₂.₅, PM₁₀, O₃, CO, NO₂, SO₂.
- city
- city_type
- year
Analyzed Variables:
- Absolute exposure burden --> The mean annual pollutant concentration * population count
- Average per-capita share of pollution (compare across cities of different sizes) --> pollutant mean / total population
- Exceedance frequency --> number of days per year each city exceeds World Health Organization (WHO) air quality guidelines (PM₂.₅ > 15 µg/m³, PM₁₀ > 45 µg/m³, O₃ > 100 µg/m³, NO₂ > 25 µg/m³)

Graphs, Maps, & Tables:
- Summary Statistics Table: mean, median, IQR, and max for each pollutant per city
- Time series plots: Use geom_line or geom_point to find annual mean concentrations per city, one panel per pollutant
