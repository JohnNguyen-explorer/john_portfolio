-- These queries below serve to provide exploratory information regarding finding the meaning behind both the separate tables regarding Covid infections and deaths
-- The other separate Vaccination table is also explored regarding Covid vaccination information
-- Both tables are also explored together to identify trends and possible relationships 

-- Objectives: Determined COVID infection cases, deaths, and rates of vaccinations with different granularity ranging from the world, continents, countries, and specific country

-- CovidDeaths table

Select *
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is null
order by 3, 4

--Select *
--From PortfolioProjectFeb2023..CovidVaccinationsFeb2023
--order by 3, 4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjectFeb2023..CovidDeathFeb2023
order by 1, 2

-- Total Cases vs Total Deaths; Percent of deaths out of total cases
-- Signifies the likelihood of death if one contracts the disease in the specified country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where Location like '%United States%'
order by 1, 2

-- Total Cases COVID Infected vs Population
Select Location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where Location like '%states%'
order by 1, 2

-- Showing what countries have the highest infected percentage of their total reported Population
Select Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProjectFeb2023..CovidDeathFeb2023
Group by location, population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count vs their total population
Select Location, MAX(cast(total_deaths as int)) as TotalDeathsCount, population
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is not null
Group by location, population
order by TotalDeathsCount desc

-- Filter including wealth classes, the world, and continents
Select location, MAX(cast(total_deaths as int)) as TotalDeathsCount
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is null
Group by location
order by TotalDeathsCount desc

-- Shows just continents
Select continent, MAX(cast(total_deaths as int)) as TotalDeathsCount
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is not null
Group by continent
order by TotalDeathsCount desc

-- Showing global number of cases, deaths, and the percentage of deaths by each recorded day in the world
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_Deaths as int)) / SUM(new_cases)*100 as DeathPercentage
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is not null
Group by date
order by 1,2 

-- For the world total number of death percentage out of the total cases
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_Deaths as int)) / SUM(new_cases)*100 as DeathPercentage
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is not null
order by 1,2 



-- JOINS with CovidVaccinations and CovidDeath Table

-- Confirm joining correct
Select dea.location, dea.date, vac.date, vac.location
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date

-- Confirming when all columns are shown
Select *
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date

-- Indicates the time periods before the vaccine was created and when the reporting happens for every country
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as TotalVaccinated
	--, (TotalVaccinated / population)*100
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- Sum of total vaccinated vs population of united states 
-- new_people_vaccinated_smoothed column is not aggregated by default 
SELECT  dea.location, dea.population, 
	SUM(cast(vac.new_people_vaccinated_smoothed as bigint)) as TotalVaccinated, 
	(SUM(cast(vac.new_people_vaccinated_smoothed as bigint)) / dea.population) * 100 as TotalVaccinatedPercent
FROM PortfolioProjectFeb2023..CovidDeathFeb2023 dea
	JOIN PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location like 'united states'
	--AND dea.continent is not null
GROUP BY dea.location, dea.population

-- new_vaccinations takes into account second dosages for people indicating a misleading vaccinated percent if aggregating that column
SELECT  dea.location, dea.population, 
	SUM(cast(vac.new_vaccinations as bigint)) as TotalVaccinated, 
	(SUM(cast(vac.new_vaccinations as bigint)) / dea.population) * 100 as TotalVaccinatedPercent
FROM PortfolioProjectFeb2023..CovidDeathFeb2023 dea
	JOIN PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location like 'united states'
	--AND dea.continent is not null
GROUP BY dea.location, dea.population

-- Identifies the total population of the U.S. as a constant value
SELECT location, population
FROM PortfolioProjectFeb2023..CovidDeathFeb2023
WHERE location like 'united states'

-- Identifies that this new_people_vaccinated_smoothed column is not aggregated, each entry is a new set of values
select location, new_people_vaccinated_smoothed, date
from PortfolioProjectFeb2023..CovidVaccinationsFeb2023
where location like 'united states'
order by 3

-- Identifies that these columns are aggregated by default where each entry is the sum of a new set of vaccination numbers and the previous recorded number vaccinations
select location, people_vaccinated, people_fully_vaccinated, total_vaccinations, date
from PortfolioProjectFeb2023..CovidVaccinationsFeb2023
where location like 'united states'
order by date

-- View all columns of the Vaccination information table for the U.S.
select *
from PortfolioProjectFeb2023..CovidVaccinationsFeb2023
where location like 'united states'
order by 4

-- CTE

-- Using cte to display aggregated number of people who received first vaccination by every date for each country

With PopulationvsVaccinated (Continent, Location, date, population, new_vaccinations, TotalVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_people_vaccinated_smoothed as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as ChangingTotalVaccinated
	--, (TotalVaccinated / population)*100
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
	Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
Select *, (TotalVaccinated / population)*100 as PopulationVaccinatedPercentage
From PopulationvsVaccinated
ORDER BY location, date

-- Temp Table

-- Using Temp table to identify the trend of total vaccinations over the years
Drop Table if exists #PercentPopulationVaccinated2023
Create Table #PercentPopulationVaccinated2023
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_People_Vaccinated_Smoothed numeric,
ChangingTotalVaccinated numeric
)

Insert into #PercentPopulationVaccinated2023
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_people_vaccinated_smoothed as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as ChangingTotalVaccinated
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
	AND dea.location like 'united states' 
order by dea.location, dea.date, dea.population

Select*, (ChangingTotalVaccinated / population)*100 as PercentPopulationVaccinated
From #PercentPopulationVaccinated2023


-- Views

-- Creating view to store data for later visualizations of the total vaccinations over the years for each country
DROP VIEW IF EXISTS PercentPopulationVaccinated2023

Create View PercentPopulationVaccinated2023 as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(convert(bigint, vac.new_people_vaccinated_smoothed)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as IncreasingTotalVaccinated
FROM PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed

Select *,  (IncreasingTotalVaccinated / population) * 100 as TotalVaccinatedPercent
From PercentPopulationVaccinated2023
ORDER BY location, date


-- Creating view for another visualization of the total infection cases over the years for each country 
DROP VIEW IF EXISTS PercentPopulationInfections2023

Create View PercentPopulationInfections2023 as
Select dea.continent, dea.location, dea.date, dea.population, dea.new_cases
, SUM(convert(bigint, dea.new_cases)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as IncreasingTotalCases
FROM PortfolioProjectFeb2023..CovidDeathFeb2023 dea
WHERE dea.continent is not null
GROUP BY dea.continent, dea.location, dea.date, dea.population, dea.new_cases

Select *,  (IncreasingTotalCases/ population) * 100 as TotalCasesPercent
From PercentPopulationInfections2023
ORDER BY location, date


-- Creating view for visualization of the total deaths over the years for each country out of their total population
DROP VIEW IF EXISTS PercentPopulationDeaths2023

Create View PercentPopulationDeaths2023 as
Select dea.continent, dea.location, dea.date, dea.population, dea.new_deaths
, SUM(convert(bigint, dea.new_deaths)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as IncreasingTotalDeaths
FROM PortfolioProjectFeb2023..CovidDeathFeb2023 dea
WHERE dea.continent is not null
GROUP BY dea.continent, dea.location, dea.date, dea.population, dea.new_deaths

Select *,  (IncreasingTotalDeaths/ population) * 100 as TotalDeathsPercent
From PercentPopulationDeaths2023
ORDER BY location, date
