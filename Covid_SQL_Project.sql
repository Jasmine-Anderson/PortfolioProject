/*
Covid 19 Data Exploration

Data Time period 2/2/2020-2/2/2022

Skills used Joins, CTE's Temp Tables, Windows Functions, Aggregate Functions, Creating views, Converting Data Types

*/


SELECT * 
FROM Portfolio_Project..Covid_Deaths$
Where continent is not null
ORDER BY 3, 4;


-- Selecting the data to start with

SELECT location, date, total_cases, new_cases, population
FROM Portfolio_Project..Covid_Deaths$
Where continent is not null
ORDER by 1,2;

-- Total Cases vs Total Deaths
-- This shows the liklihood of dying if you contract covid in the United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM Portfolio_Project..Covid_Deaths$
WHERE location like 'United States'
and continent is not null
ORDER by 1,2;

-- Total cases vs Population
-- This shows what percentage of population contracted covid in the United States

SELECT location, date, population, total_cases, (total_cases/population)*100 as Case_Percentage
FROM Portfolio_Project..Covid_Deaths$
WHERE location like 'United States'
and continent is not null
ORDER by 1,2;

--Countries with the highest infection rate compared to populatiom

SELECT location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as 
PercentagePopulationInfected
FROM Portfolio_Project..Covid_Deaths$
Where continent is not null
GROUP BY Location, population
ORDER by PercentagePopulationInfected desc;

--Countries with the highest death count per population

SELECT location, population, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM Portfolio_Project..Covid_Deaths$
Where continent is not null
GROUP BY Location, population
ORDER by TotalDeathCount desc;


--Now I will break down by continent
--Continents with the highes death count per population

SELECT continent, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM Portfolio_Project..Covid_Deaths$
Where continent is not null
GROUP BY continent
ORDER by TotalDeathCount desc;

SELECT location, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM Portfolio_Project..Covid_Deaths$
Where continent is  null
and location not like '%income%' 
GROUP BY location
ORDER by TotalDeathCount desc;


-- breaking things down by income level

SELECT location, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM Portfolio_Project..Covid_Deaths$
Where continent is null
and location like '%income%'
GROUP BY location
ORDER by TotalDeathCount desc;


-- Global numbers


SELECT SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as bigint)) as TotalNewDeaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as deathPercentages
FROM Portfolio_Project..Covid_Deaths$
Where continent is not null
ORDER by 1,2


-- Total population vs Vaccinations
-- This shows the percentage of poulation that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date,  dea.population, vac.new_vaccinations 
from Portfolio_Project..Covid_Deaths$ dea
join Portfolio_Project..Covid_Vaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--Using CTE to perform Calculations on Partition By in previous query

With PopvsVac (Continent, Location, Data, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date,  dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from Portfolio_Project..Covid_Deaths$ dea
join Portfolio_Project..Covid_Vaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100 as PercentPopVaccinated
from PopvsVac



--Using Tenp Table to perform Calculation on Partition By in previous query

DROP table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date,  dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from Portfolio_Project..Covid_Deaths$ dea
join Portfolio_Project..Covid_Vaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/population)*100 as PercentPopVaccination
from #PercentPopulationVaccinated


--creating view to store data for later visulaization

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date,  dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from Portfolio_Project..Covid_Deaths$ dea
join Portfolio_Project..Covid_Vaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *
From PercentPopulationVaccinated
