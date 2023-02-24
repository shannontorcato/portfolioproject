SELECT *
FROM PortfolioDatabase..covid_deaths
WHERE continent is NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioDatabase..covid_vaccinations
--ORDER BY 3,4

--Select data that we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioDatabase..covid_deaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if contract Covid
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioDatabase..covid_deaths
WHERE location like 'India'
ORDER BY 1,2

-- Looking at Total Cases vs Population

SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
FROM PortfolioDatabase..covid_deaths
WHERE location like 'India'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as InfectionRate
FROM PortfolioDatabase..covid_deaths
-- WHERE location like 'India'
GROUP BY location, population
ORDER BY InfectionRate desc

-- Shows the Countries with Highest Death Count Per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 
FROM PortfolioDatabase..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Lest's Break The Location Down To Continent

--SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
--FROM PortfolioDatabase..covid_deaths
--WHERE continent IS NULL 
--	AND location NOT LIKE '%income%'
--GROUP BY location
--ORDER BY TotalDeathCount DESC

-- Shwoing Continents With Highest Death Count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioDatabase..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
SELECT date, SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioDatabase..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Using CTE

WITH popVSvac (continent, location, date, population, new_vaccination, cumsumvaccination)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumSumVaccination
FROM PortfolioDatabase..covid_deaths dea
JOIN PortfolioDatabase..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (cumsumvaccination/population)*100
FROM popVSvac

-- Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
data datetime,
population numeric,
new_vaccination numeric,
cumsumvaccination numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumSumVaccination
FROM PortfolioDatabase..covid_deaths dea
JOIN PortfolioDatabase..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (cumsumvaccination/population)*100 AS vaccinationpercentage
FROM #PercentPopulationVaccinated

-- Creating View For Later Visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumSumVaccination
FROM PortfolioDatabase..covid_deaths dea
JOIN PortfolioDatabase..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL