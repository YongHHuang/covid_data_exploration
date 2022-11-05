----------COMMAND--------------------------------------------------

SELECT * 
FROM Covid_Data_Exploration..covid_death
ORDER BY 3,4

----------COMMAND--------------------------------------------------

SELECT * 
FROM Covid_Data_Exploration..covid_vaccination
ORDER BY 3,4

----------COMMAND--------------------------------------------------

SELECT location, date, new_cases, total_cases, total_deaths, population
FROM Covid_Data_Exploration..covid_death
ORDER BY 1,2

----------COMMAND--------------------------------------------------

-- Mortality Rate(Case Fatality and Death per 100,000 Population)
SELECT location, date, total_cases, total_deaths, population,
	ROUND((total_deaths / total_cases) * 100, 2) AS case_fatality_rate,
	(total_deaths / population * 100000) AS death_per_100k
FROM Covid_Data_Exploration..covid_death
ORDER BY 1,2

----------COMMAND--------------------------------------------------

-- Mortality Rate(Case Fatality and Death per 100,000 Population) in the U.S.
SELECT location, date, total_cases, total_deaths, population, 
	ROUND((total_deaths / total_cases) * 100, 2) AS case_fatality_rate, 
	(total_deaths / population * 100000) AS death_per_100k
FROM Covid_Data_Exploration..covid_death
WHERE location LIKE '%states%'
ORDER BY 1,2

----------COMMAND--------------------------------------------------

-- Infection Rate in the U.S.
SELECT location, date, total_cases, population, 
	ROUND((total_cases / population * 100), 3) AS infection_rate
FROM Covid_Data_Exploration..covid_death
WHERE location LIKE '%states%'
ORDER BY 1,2

----------COMMAND--------------------------------------------------

-- Countries with the Highest Infection Rate
SELECT location, 
	MAX(total_cases) AS max_cases, 
	population,
	MAX(total_cases) / population * 100 AS infection_rate
FROM Covid_Data_Exploration..covid_death
GROUP BY location, population
ORDER BY 4 DESC

----------COMMAND--------------------------------------------------

-- Countries with the Highest Death Count
SELECT location, MAX(CAST(total_deaths AS INT)) AS max_death
FROM Covid_Data_Exploration..covid_death
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

----------COMMAND--------------------------------------------------

-- Continents with the Highest Death Count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS max_death
FROM Covid_Data_Exploration..covid_death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

----------COMMAND--------------------------------------------------

-- Global Numbers(Each Day)
SELECT date, 
	SUM(new_cases) AS new_cases, 
	SUM(CAST(new_deaths AS INT)) AS new_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS case_fatality
FROM Covid_Data_Exploration..covid_death
WHERE continent is not NULL
GROUP BY date
ORDER BY 1

----------COMMAND--------------------------------------------------

-- Global Numbers(Total)
SELECT SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS case_fatality
FROM Covid_Data_Exploration..covid_death
WHERE continent IS NOT NULL

----------COMMAND--------------------------------------------------

-- Join covid_death and covid_vaccination On Location and Date
SELECT * 
FROM Covid_Data_Exploration..covid_death dea
JOIN Covid_Data_Exploration..covid_vaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date

----------COMMAND--------------------------------------------------

-- New Vaccinations
SELECT dea.location, dea.continent, dea.date, dea.population, vac.new_vaccinations
FROM Covid_Data_Exploration..covid_death dea
JOIN Covid_Data_Exploration..covid_vaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3

----------COMMAND--------------------------------------------------

-- Accumulated vaccinations in Each Country
SELECT dea.location, dea.continent, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS accumulated_vaccinaiton
FROM Covid_Data_Exploration..covid_death dea
JOIN Covid_Data_Exploration..covid_vaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 3

----------COMMAND--------------------------------------------------

-- Accumulated vaccination Rate in Each Country
WITH vac_rate AS
	(
		SELECT dea.location, dea.continent, dea.date, dea.population, vac.new_vaccinations,
			SUM(CAST(vac.new_vaccinations AS BIGINT)) 
				OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS accumulated_vaccination
		FROM Covid_Data_Exploration..covid_death dea
		JOIN Covid_Data_Exploration..covid_vaccination vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
	)
SELECT *, (accumulated_vaccination / population * 100) AS vaccination_rate
FROM vac_rate
ORDER BY 1, 3

----------COMMAND--------------------------------------------------

-- Create View to store data for visualizations
CREATE VIEW Covid_Data_Exploration..countries_vaccination_rate AS
	WITH vac_rate AS		
		(
			SELECT dea.location, dea.continent, dea.date, dea.population, vac.new_vaccinations,
				SUM(CAST(vac.new_vaccinations AS BIGINT)) 
					OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS accumulated_vaccination
			FROM Covid_Data_Exploration..covid_death dea
			JOIN Covid_Data_Exploration..covid_vaccination vac
				ON dea.location = vac.location
				AND dea.date = vac.date
			WHERE dea.continent IS NOT NULL
		)
	SELECT *, (accumulated_vaccination / population * 100) AS vaccination_rate
	FROM vac_rate



----------------------------------------------------------------------------------------	
-- Create 6 Tables for visualization
----------------------------------------------------------------------------------------

-- 1 Global numbers (total cases, total deaths, mortality_rate)
SELECT 
    SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS BIGINT)) AS total_deaths,
	ROUND(SUM(CAST(new_deaths AS BIGINT)) / SUM(new_cases) * 100, 2) AS mortality_rate
INTO Covid_Data_Exploration..global_numbers
FROM Covid_Data_Exploration..covid_death
WHERE continent IS NOT NULL


-- 2 Total deaths each continent

SELECT 
	location,  
	SUM(CAST(new_deaths AS INT)) AS total_deaths
INTO Covid_Data_Exploration..continent_total_deaths
FROM Covid_Data_Exploration..covid_death
WHERE 
	continent IS NULL
	AND location IN ('Asia', 'Africa', 'Oceania', 'North America', 'South America', 'Europe')
GROUP BY location


--3 Max infection and infection rate for all location

SELECT 
	location, 
	population, 
	MAX(total_cases) AS total_cases,
	MAX(total_cases / population) * 100 AS infection_rate
INTO Covid_Data_Exploration..all_infection
FROM Covid_Data_Exploration..covid_death
GROUP BY location, population
ORDER BY infection_rate DESC


-- 4 Infection and infection rate for all location across time

SELECT 
	location, 
	date, 
	population,
	MAX(total_cases) AS infection, 
	MAX(total_cases / population) * 100 AS infection_rate
INTO Covid_Data_Exploration..infection_time
FROM Covid_Data_Exploration..covid_death
GROUP BY location, date, population
ORDER BY 
	infection_rate DESC,
	date DESC
