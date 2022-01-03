-- first create database
create database [Portfolio Project];

-- then use the database created
use [Portfolio Project];

-- to view the data in table
select * from dbo.CovidDeath$
order by location, date;

select * from dbo.CovidVaccination$
order by location, date;

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeath$
order by location, date;

--looking at total cases vs total death
-- shows likelihood of  if contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
from CovidDeath$
where location = 'Malaysia'
order by location, date;

--looking at the total cases vs population
select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from CovidDeath$
order by location, date;

--looking at country with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectCount, Max((total_cases/population))*100 as PercentPopulationInfected
from CovidDeath$
group by location,population 
order by PercentPopulationInfected desc;

--showing countries with highest death count per population
-- continent is null
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeath$
where continent is null
group by location
order by TotalDeathCount desc;

-- continent not null
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeath$
where continent is not null
group by continent
order by TotalDeathCount desc;

-- let's break things down by continent

-- showing continents with the highest deaths count per population
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeath$
where continent is not null
group by continent
order by TotalDeathCount desc;

-- global numbers
-- total cases worldwide sort by total cases and total deaths
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from CovidDeath$
where continent is not null
order by total_cases,total_deaths;

--looking at total of patients in icu 
select sum(cast (icu_patients as int)) as total_icu_patients, sum(cast (icu_patients as int))/sum(new_cases) as icu_percentage
from dbo.CovidDeath$
where location = 'Malaysia'

--looking at total of patients admission due to Covid-19
select sum(cast(hosp_patients as int)) as total_hosp_patients, sum(cast (hosp_patients as int))/sum(new_cases) as hosp_percentage
from dbo.CovidDeath$
where location = 'Malaysia'

-- join covid death table with covid vaccination
select * from CovidDeath$ d
join CovidVaccination$ v
on d.location = v.location and d.date = v.date
order by 3,4;

-- looking for total population vs vaccinations
-- since there is an error 8115 while converting variable
-- for v.new_vaccinations, i choose bigint instead of int 
-- due to large number of data types
select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date)
as CumulativeVaccinated
from CovidDeath$ d
join CovidVaccination$ v
	on d.location = v.location 
	and d.date = v.date
	where d.continent is not null
order by 2,3;


-- using common table expression (cte) --temporary named result set
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CummulativeVaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(bigint,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as CumulativeVaccinated
From CovidDeath$ d
Join CovidVaccination$ v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
)
Select *, (CummulativeVaccinated/Population)*100
From PopvsVac;

-- create table percent population vaccinated for easier query
drop table if exists #PercentPopulationVaccinated;

create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CumulativeVaccinated numeric
);

Insert into #PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(bigint,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as CumulativeVaccinated
From CovidDeath$ d
Join CovidVaccination$ v
	On d.location = v.location
	and d.date = v.date

Select *, (CumulativeVaccinated/Population)*100
From #PercentPopulationVaccinated;

-- creating view to store data 
create view PercentPopulationVaccinated as 
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as CumulativeVaccinated
from CovidDeath$ d
join CovidVaccination$ v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null;

select *
from PercentPopulationVaccinated;
