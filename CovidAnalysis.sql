USE PortfolioProject

-- The CSV Files are imported through Import Wizard. Allowed Nulls in all columns and changed most data types to floats.


-- Look at death percents out of those with Covid. Shows the severity of Covid throughout time, in different locations.
SELECT top 500
    [location], [date], total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Death_Percent
FROM CovidDeaths
WHERE location = 'United States'
ORDER BY location, date DESC

-- Look at total cases vs population. Shows the percentage of the population in a given location that got Covid.
SELECT top 500
    [location], [date], total_cases, [population], (total_cases/[population]) * 100 AS Case_Percent, (total_deaths/total_cases) * 100 AS Death_Percent
FROM CovidDeaths
WHERE location = 'United States'
ORDER BY Case_Percent DESC

-- Look at countries with the highest infection rate
SELECT [location], MAX((total_cases/[population]) * 100) AS Highest_InfectionRate_AllTime
FROM CovidDeaths
GROUP BY [location]
ORDER BY Highest_InfectionRate_AllTime DESC

-- Look at countries with the highest mortality rate due to Covid
SELECT [location], MAX(total_deaths) TotalDeaths, MAX((total_deaths/[population]) * 100) AS Highest_Death_Percent
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY [location]
ORDER BY TotalDeaths DESC

-- Here we find that the "location" column is not clean. It has values like "World," "High income," "Asia," etc.
-- We solve this by adding "WHERE Continent is NOT NULL," which gives us all the countries within a continent.

-- Now let's sort by continent. Continent with the highest death count.
SELECT [continent], MAX(total_deaths) TotalDeaths, MAX((total_deaths/[population]) * 100) AS Highest_Death_Percent
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeaths DESC

-- Global Numbers
SELECT [date], SUM(new_cases) SumNewCases, SUM(new_deaths) SumNewDeaths, SUM(new_deaths) / SUM(new_cases) * 100 as SumDeathPercents
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY [date]

-- Look at Total Population vs Vaccination
SELECT d.continent, d.[location], d.[date], d.[population], new_vaccinations,
    SUM(new_vaccinations) OVER (PARTITION BY d.[location] ORDER BY d.location, d.date) RollingPeepsVaxxed
FROM CovidVax V
    JOIN CovidDeaths D ON (V.[location] = D.[location] AND V.[date] = D.[date])
WHERE d.continent IS NOT NULL
ORDER BY location, date
-- Use CTE to get the ratio of rolling peeps vaxxed in the whole population
WITH
    CTE_Pop_Vaxxed (continent, loc, [date], pop, new_vax, roll_vax)
    AS
    (
        SELECT d.continent, d.[location], d.[date], d.[population], new_vaccinations,
            SUM(new_vaccinations) OVER (PARTITION BY d.[location] ORDER BY d.location, d.date) as RollingPeepsVaxxed
        FROM CovidVax V
            JOIN CovidDeaths D ON (V.[location] = D.[location] AND V.[date] = D.[date])
        WHERE d.continent IS NOT NULL
    )
SELECT *, (roll_vax / [pop]) * 100
FROM CTE_Pop_Vaxxed


-- Use Temp Table
DROP TABLE IF EXISTS #PercentVaxxed
CREATE TABLE #PercentVaxxed
(
    Continent varchar(100),
    [LOCATION] varchar(100),
    [Date] Date,
    [Population] FLOAT,
    New_Vax FLOAT,
    Roll_Vax FLOAT
)

INSERT INTO #PercentVaxxed
SELECT d.continent, d.[location], d.[date], d.[population], new_vaccinations,
    SUM(new_vaccinations) OVER (PARTITION BY d.[location] ORDER BY d.location, d.date) RollingPeepsVaxxed
FROM CovidVax V
    JOIN CovidDeaths D ON (V.[location] = D.[location] AND V.[date] = D.[date])
WHERE d.continent IS NOT NULL
ORDER BY location, date

SELECT *, (roll_vax / [population]) * 100
FROM #PercentVaxxed
GO
-- Create View to store data for later visualizations

CREATE VIEW PercentVaxxedByContinent
AS
    (
    SELECT [continent], MAX(total_deaths) TotalDeaths, MAX((total_deaths/[population]) * 100) AS Highest_Death_Percent
    FROM CovidDeaths
    WHERE Continent IS NOT NULL
    GROUP BY [continent]
)
GO
SELECT *
FROM PercentVaxxedByContinent


/*
Queries used for later Tableau Visualization
*/



-- 1. 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
--Where location like '%states%'
where continent is not null
--Group By date
order by 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null
    and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.


Select Location, Population, date, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc