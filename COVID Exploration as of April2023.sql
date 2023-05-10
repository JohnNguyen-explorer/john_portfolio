-- Third Iteration of CovidProject Updated to April 2023 and Now focused on use case of identifying countries that need more efforts in vaccinations

-- Looking at COVID-19 Infection Mortality Table

-- Identifying non countries
Select continent, location
From CovidProjectApril2023..[Infection Mortality Table]
Where continent is null
Group by continent, location

-- Showing only countries and related entities
Select continent, location
From CovidProjectApril2023..[Infection Mortality Table]
Where location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
--Where location like 'united states'
Group by continent, location
Order by continent

-- Showing the total number of COVID-19 cases for each country over time and percentage of its population infected
Select location, date, population, new_cases,
SUM(cast(new_cases as bigint)) OVER (Partition by location Order by location, date) as total_infected,
new_deaths,
SUM(cast(new_deaths as bigint)) OVER (Partition by location Order by location, date) as total_deaths,
(SUM(cast(new_cases as bigint)) OVER (Partition by location Order by location, date)/ population) * 100 as percentage_infected
From CovidProjectApril2023..[Infection Mortality Table] 
--Where location like 'united states'
--Where location like 'Mauritania'
--AND SUM(cast(new_cases as bigint)) OVER (Partition by location Order by location, date) != 0
Order by location, date


-- Showing COVID-19 daily infection cases, total infection cases, daily deaths, total deaths, and case fatality rates over time
-- Using temp table to address divide by zero error and windowed functions not in select or order by clause error
Drop Table if exists #CaseFatalityRate
Create Table #CaseFatalityRate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_cases numeric,
total_infections numeric,
new_deaths numeric,
total_mortalities numeric
)

Insert into #CaseFatalityRate
Select continent, location, date, population, new_cases, 
SUM(cast(new_cases as bigint)) OVER (Partition by location Order by location, date) as total_infections,
new_deaths, 
SUM(cast(new_deaths as bigint)) OVER (Partition by location Order by location, date) as total_mortalities
From CovidProjectApril2023..[Infection Mortality Table]
Where continent is not null
and location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
Order by location, date

-- Showing the case_fatality_rate over time for each country
Select *, (total_mortalities / total_infections) * 100 as case_fatality_rate
From #CaseFatalityRate
Where total_infections != 0
Order by location, date

-- Comparing case_fatality_rates after the first vaccine was administered in the world
Select location, date, (total_mortalities / total_infections) * 100 as case_fatality_rate
From #CaseFatalityRate
Where total_infections != 0
AND date >= '2020-12-04'
Group by location, date,(total_mortalities / total_infections) * 100
Order by location, date, case_fatality_rate desc

-- Comparing case_fatality_rates before the first vaccine was administered in the world
Select location, date, (total_mortalities / total_infections) * 100 as case_fatality_rate
From #CaseFatalityRate
Where total_infections != 0
AND date < '2020-12-04'
Group by location, date,(total_mortalities / total_infections) * 100
Order by location, date, case_fatality_rate desc

-- Found outliers and compared with United States rates
Select location, MAX(total_mortalities / total_infections) * 100 as case_fatality_rate
From #CaseFatalityRate
Where total_infections != 0
AND location in ('Mauritania', 'Zimbabwe', 'Philippines','United States')
Group by location
Order by case_fatality_rate desc

-- Exploring the outliers of case_fatality_rates before the vaccine
Select *, (total_mortalities / total_infections) * 100 as case_fatality_rate
From #CaseFatalityRate
Where total_infections != 0
And location in ('Mauritania', 'Zimbabwe', 'Philippines','United States','Sudan',
'Ireland', 
'Cayman Islands','United Kingdom','Guyana','Democratic Republic of Congo')
AND date < '2020-12-04'
Order by location, date




-- Looking at COVID-19 Health Table

-- Column Names
Select *
From CovidProjectApril2023..[Health Table]
--Where location like 'united states'
Order by location, date


-- Showing the total number of people vaccinated for COVID-19 with least one dose for each country over time, United States
Select location, date, population, people_vaccinated, people_fully_vaccinated, 
convert(bigint, people_vaccinated) + convert(bigint, people_fully_Vaccinated) as total_doses_administered
From CovidProjectApril2023..[Health Table]
Where location like 'united states'
Order by location, date

-- Showing total vaccinated percentage of each country's population for at least one COVID-19 dose and full dosage over time, United States
Select location, date, population, people_vaccinated, people_fully_vaccinated, new_people_vaccinated_smoothed,
(convert(bigint, people_vaccinated) / population) * 100 as PercentVaccinated,
(convert(bigint, people_fully_vaccinated) / population) * 100 as PercentFullyVaccinated
From CovidProjectApril2023..[Health Table]
--Where location like 'united states'
Order by location, date

-- Identifying the earliest date vaccines administered in the world
Select location, date, population, people_vaccinated
From CovidProjectApril2023..[Health Table]
Where location in ('World')
Order by location, date

-- Temp Table fixing challenge of logical error given data type changed and expected output between percentage calculation vaccinated
Drop Table if exists #VaccinationCountry
Create Table #VaccinationCountry
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
people_vaccinated numeric,
people_fully_vaccinated numeric,
)

Insert into #VaccinationCountry
Select continent, location, date, population, people_vaccinated, people_fully_vaccinated
From CovidProjectApril2023..[Health Table]
Where continent is not null
and location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
Order by location, date

-- Identifying most recent dated countries with least vaccinated percent and removed outliers 
Select location, MAX(date) as recent, population, 
MAX(people_vaccinated) as people_vac, 
MAX(people_fully_vaccinated) as people_full,
MAX(people_vaccinated / Population) * 100 as vaccinatedpercent,
MAX(people_fully_vaccinated / Population) * 100 as vaccinatedpercentfull
From #VaccinationCountry
Where  people_fully_vaccinated != 0 
Group by location, population
Having MAX(people_fully_vaccinated / Population) * 100 <= 100
Order by MAX(people_fully_vaccinated / Population) * 100 asc


-- Looking with Hospital bed,life expectancy, percentage smoking
-- Outliers missing life expectancy Kosovo Northern Cyprus Guernsey Pitcairn Jersey Northern Ireland Wales Scotland England
Drop Table if exists #VacPercentHospitalLifeSmoke
Create Table #VacPercentHospitalLifeSmoke
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
people_vaccinated numeric,
people_fully_vaccinated numeric,
female_smokers numeric(10,2),
male_smokers numeric(10,2),
hospital_beds_per_thousand numeric(10,3),
life_expectancy numeric (10,2)
)

Insert into #VacPercentHospitalLifeSmoke
Select continent, location, date, population, people_vaccinated, people_fully_vaccinated, female_smokers,
male_smokers,
hospital_beds_per_thousand,
life_expectancy
From CovidProjectApril2023..[Health Table]
Where continent is not null
and location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
and hospital_beds_per_thousand is not null
and life_expectancy is not null
and female_smokers is not null
and male_smokers is not null
Order by location, date

-- Showing most recent dated country information of their life expectancy and percent vaccinated starting from least life expectancy
Select location, MAX(date) as recent, population, 
MAX(people_vaccinated) as people_vac, 
MAX(people_fully_vaccinated) as people_full,
MAX(people_vaccinated / Population) * 100 as vaccinatedpercent,
MAX(people_fully_vaccinated / Population) * 100 as vaccinatedpercentfull,
MAX(female_smokers) as percentfemalesmoke,
MAX(male_smokers) as percentmalesmoke,
MAX(hospital_beds_per_thousand) / 10 as hospital_bed_per_100_ppl,
MAX(life_expectancy) as life_expectancy
From #VacPercentHospitalLifeSmoke
Where  people_fully_vaccinated != 0
Group by location, population
Order by MAX(life_expectancy) asc

-- Showing the most recent dated information of each country regarding which ones have the least available hospital beds
Select location, MAX(date) as recent, population, 
MAX(people_vaccinated) as people_vac, 
MAX(people_fully_vaccinated) as people_full,
MAX(people_vaccinated / Population) * 100 as vaccinatedpercent,
MAX(people_fully_vaccinated / Population) * 100 as vaccinatedpercentfull,
MAX(hospital_beds_per_thousand) / 10 as hospital_bed_per_100_ppl
From #VacPercentHospitalLifeSmoke
Where  people_fully_vaccinated != 0
Group by location, population
Order by MAX(hospital_beds_per_thousand) / 10 asc



-- CTE Attempt, challenge between convert to int leading to 100 or 0 percent, otherwise logical error given number of digits
With VaccinationsCountry (Continent, Location, date, population, people_vaccinated, people_fully_vaccinated)
as
(
Select continent, location, date, population, people_vaccinated, people_fully_vaccinated
From CovidProjectApril2023..[Health Table]
Where continent is not null
AND location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
)
Select location, MAX(date) as most_recent_date, population, 
MAX(people_vaccinated) as people_vaccinated, 
MAX(people_fully_vaccinated) as people_fully_vaccinated,
MAX(people_vaccinated / population) * 100 as PeopleVaccinatedPercent, 
MAX(people_fully_vaccinated / population) * 100 as PeopleFullyVaccinatedPercent
From VaccinationsCountry
Where people_fully_vaccinated != 0
--Where location like 'United States'
--AND date >= '2023-01-01' And date <= '2023-04-25'
Group by location, population
Order by MAX(people_fully_vaccinated / population) * 100 desc

-- Looking at Gov Economic Table

Select *
From CovidProjectApril2023..[Economic Gov Table]

-- Showing the most recent stringency indexes of each country issue not numeric stringency
Select continent, location, population, MAX(date) as mostrecent, MAX(stringency_index) as stringency_index
From CovidProjectApril2023..[Economic Gov Table]
Where continent is not null
AND location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
and stringency_index is not null
Group by continent, location, population
Order by MAX(stringency_index) asc

-- Using Temp table to assign numerics with right decimals
Drop Table if exists #GovEconomic
Create Table #GovEconomic
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
population_density numeric(10,2),
median_age numeric(10,2),
aged_70_older numeric(10,2),
gdp_per_capita numeric(10,2),
extreme_poverty numeric(10,2),
human_development_index numeric(10,3),
stringency_index numeric(10,2)
)

Insert into #GovEconomic
Select continent, location, date, population, population_density, median_age, aged_70_older, gdp_per_capita, extreme_poverty, 
human_development_index, stringency_index
From CovidProjectApril2023..[Economic Gov Table]
Where continent is not null
AND location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
AND extreme_poverty is not null
AND gdp_per_capita is not null
AND human_development_index is not null
and stringency_index is not null
Order by location, date

-- Identifying Countries with the most in extreme poverty 
Select location, population, MAX(extreme_poverty) as extreme_poverty
From #GovEconomic
Group by location, population
Order by MAX(extreme_poverty) desc

-- Identifying Countries with the least GDP
Select location, population, MIN(gdp_per_capita) as gdp
From #GovEconomic
Group by location, population
Order by MIN(gdp_per_capita) 

-- Identifying Countries with the least HDI
Select location, population, MIN(human_development_index) as HDI
From #GovEconomic
Group by location, population
Order by MIN(human_development_index) asc

-- Identifying Countries with the least SI as of recent reported date
Select location, MAX(date) as mostrecent, population, stringency_index
From #GovEconomic
Group by location, population, stringency_index
Order by MAX(date) desc

-- Identifying all countries based on this 



-- Identifying Countries starting from least HDI, most extreme poverty, least GDP, based on each reported SI date
Select location, MAX(date) as date, population, MAX(extreme_poverty) as extreme_poverty,
MIN(gdp_per_capita) as gdp,
MIN(human_development_index) as HDI,
stringency_index
From #GovEconomic
Group by location, population, stringency_index
Order by MIN(human_development_index), MIN(gdp_per_capita), MAX(extreme_poverty), location, MAX(date)




-- Using Joins and Views to facilitate Tableau Visuals
-- Testing joins
Select inf.location, inf.date, hea.location, hea.date, eco.location, eco.date
From CovidProjectApril2023..[Infection Mortality Table] inf
Join [Health Table] hea on inf.location = hea.location 
and inf.date = hea.date
Join [Economic Gov Table] eco on inf.location = eco.location
and inf.date = eco.date
Order by inf.location, inf.date

-- Tableau Visual Global Trends
DROP VIEW IF EXISTS GlobalTrends

Create View GlobalTrends as 
Select inf.location, inf.date, inf.population, inf.new_cases, 
SUM(cast(inf.new_cases as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) as total_infections,
(SUM(cast(inf.new_cases as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) / inf.population) * 100 as infected_percent,
inf.new_deaths,
SUM(cast(inf.new_deaths as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) as total_mortalities,
(SUM(cast(inf.new_deaths as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) / 
SUM(cast(inf.new_cases as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date)) * 100 as case_fatality_rate,
hea.people_vaccinated,
(SUM(cast(hea.people_vaccinated as bigint)) / inf.population) * 100 as vaccinated_percent,
hea.people_fully_vaccinated,
(SUM(cast(hea.people_fully_vaccinated as bigint)) / inf.population) * 100 as fully_vaccinated_percent
From CovidProjectApril2023..[Infection Mortality Table] inf
Join [Health Table] hea on inf.location = hea.location 
and inf.date = hea.date
Join [Economic Gov Table] eco on inf.location = eco.location
and inf.date = eco.date
Where inf.location in ('World')
Group by inf.location, inf.date, inf.population, inf.new_cases, inf.new_deaths, hea.people_vaccinated, hea.people_fully_vaccinated

Select * 
From GlobalTrends
Where total_infections != 0
Order by location, date

-- Tableau Visual Country Trends
DROP VIEW IF EXISTS CountryTrends

Create View CountryTrends as
Select inf.continent, inf.location, inf.date, inf.population, inf.new_cases,
SUM(cast(inf.new_cases as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) as total_infections,
(SUM(cast(inf.new_cases as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) / inf.population) * 100 as infected_percent,
inf.new_deaths, 
SUM(cast(inf.new_deaths as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) as total_mortalities,
(SUM(cast(inf.new_deaths as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date) / 
SUM(cast(inf.new_cases as decimal(10,2))) OVER (Partition by inf.location Order by inf.location, inf.date)) * 100 as case_fatality_rate,
hea.people_vaccinated,
(SUM(cast(hea.people_vaccinated as bigint)) / inf.population) * 100 as vaccinated_percent,
hea.people_fully_vaccinated,
(SUM(cast(hea.people_fully_vaccinated as bigint)) / inf.population) * 100 as fully_vaccinated_percent
From CovidProjectApril2023..[Infection Mortality Table] inf
Join [Health Table] hea on inf.location = hea.location 
and inf.date = hea.date
Join [Economic Gov Table] eco on inf.location = eco.location
and inf.date = eco.date
Where inf.continent is not null
and inf.location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
Group by inf.continent, inf.location, inf.population, inf.date, inf.new_cases, inf.new_deaths, hea.people_vaccinated, hea.people_fully_vaccinated

Select *
From CountryTrends
Where total_infections != 0
and people_fully_vaccinated is not null
and people_vaccinated is not null
Order by location, date

Select distinct location, date as mostrecent, fully_vaccinated_percent
From CountryTrends
Where total_infections != 0
and people_fully_vaccinated is not null
and people_vaccinated is not null
Group by location, date, fully_vaccinated_percent
Order by location, date desc, fully_vaccinated_percent

Select distinct location, date, fully_vaccinated_percent, case_fatality_rate
From CountryTrends
Where total_infections != 0
and people_fully_vaccinated is not null
and people_vaccinated is not null
Group by location, date, fully_vaccinated_percent, case_fatality_rate
Order by location, date, fully_vaccinated_percent

-- Recent reported date with vaccinated percent
Select distinct location, MAX(date), MAX(population) as population, MAX(people_vaccinated) as total_ppl_vaccinated,  
MAX(fully_vaccinated_percent) as vaccinatedpercent
From CountryTrends
Where total_infections != 0
and people_fully_vaccinated is not null
and people_vaccinated is not null
Group by location
Order by location


-- Determining visualization for government measures relationship with vaccinated percentages 
DROP VIEW IF EXISTS CountryMeasuresVaccine

Create View CountryMeasuresVaccine as
Select inf.continent, inf.location, inf.date, inf.population, eco.stringency_index, eco.gdp_per_capita, 
eco.human_development_index, (hea.hospital_beds_per_thousand) / 10 as hospital_bed_per_100_ppl,
hea.people_vaccinated,
(SUM(cast(hea.people_vaccinated as bigint)) / inf.population) * 100 as vaccinated_percent,
hea.people_fully_vaccinated,
(SUM(cast(hea.people_fully_vaccinated as bigint)) / inf.population) * 100 as fully_vaccinated_percent
From CovidProjectApril2023..[Infection Mortality Table] inf
Join [Health Table] hea on inf.location = hea.location 
and inf.date = hea.date
Join [Economic Gov Table] eco on inf.location = eco.location
and inf.date = eco.date
Where inf.continent is not null
and inf.location not in ('High income', 'Lower middle income', 'Africa', 'Upper middle income', 'Asia', 'European Union', 
'Low income', 'Oceania', 'Europe', 'North America', 'South America', 'World')
Group by inf.continent, inf.location, inf.population, inf.date, hea.people_vaccinated, hea.people_fully_vaccinated,
eco.stringency_index, eco.gdp_per_capita, eco.human_development_index, (hea.hospital_beds_per_thousand) / 10

Select *
From CountryMeasuresVaccine
Where people_fully_vaccinated is not null
and people_vaccinated is not null
Order by location, date






