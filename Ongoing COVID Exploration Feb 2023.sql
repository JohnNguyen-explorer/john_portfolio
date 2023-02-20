

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
Where Location like '%Mongolia%'
order by 1, 2

-- Total Cases vs Population
Select Location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
From PortfolioProjectFeb2023..CovidDeathFeb2023
--Where Location like '%states%'
order by 1, 2

-- Shoing what countries have the highest infected percentage of their total reported Population
Select Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProjectFeb2023..CovidDeathFeb2023
Group by location, population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) as TotalDeathsCount
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is not null
Group by location
order by TotalDeathsCount desc

-- Filter by Continent
Select location, MAX(cast(total_deaths as int)) as TotalDeathsCount
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is null
Group by location
order by TotalDeathsCount desc

-- Shows just countries info incorrectly
Select continent, MAX(cast(total_deaths as int)) as TotalDeathsCount
From PortfolioProjectFeb2023..CovidDeathFeb2023
Where continent is not null
Group by continent
order by TotalDeathsCount desc

-- Showing global number of cases, deaths, and the percentage of deaths out of all the cases in the world
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



-- CovidVaccinations table

-- Confirm joining correct
Select dea.location, dea.date, vac.date, vac.location
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date

-- Confirming join is correct again
Select *
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date

-- Viewing Total Population vs Vaccinations 
-- Indicates the time periods before the vaccine was created and when the reporting happens
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

-- Using cte

With PopulationvsVaccinated (Continent, Location, date, population, new_vaccinations, ChangingTotalVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as ChangingTotalVaccinated
	--, (TotalVaccinated / population)*100
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)
Select*, (ChangingTotalVaccinated / population)*100 as PopulationVaccinatedPercentage
From PopulationvsVaccinated


-- Using Temp table 
Drop Table if exists #PercentPopulationVaccinated2023
Create Table #PercentPopulationVaccinated2023
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
ChangingTotalVaccinated numeric
)

Insert into #PercentPopulationVaccinated2023
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as ChangingTotalVaccinated
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2, 3

Select*, (ChangingTotalVaccinated / population)*100
From #PercentPopulationVaccinated2023

-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinated2023 as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as IncreasingTotalVaccinated
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

Select*
From PercentPopulationVaccinated




Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as TotalVaccinated
	--, (TotalVaccinated / population)*100
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3


Select dea.location, population, total_vaccinations, (total_vaccinations / population)*100 as VaccinatedPercentage
From PortfolioProjectFeb2023..CovidDeathFeb2023 dea
Join PortfolioProjectFeb2023..CovidVaccinationsFeb2023 vac
	On dea.location = vac.location
	and dea.date = vac.date
Where total_vaccinations is not null
