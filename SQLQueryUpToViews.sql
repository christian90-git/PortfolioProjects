select *
from CovidDeaths


--total cases vs total deaths
--overall death rate(how many deaths out of  running total cases)
select location, date, total_cases, new_cases, total_deaths, round((total_deaths/total_cases*100),2) as death_rate
from CovidDeaths
where location like '%States%' and total_deaths is not null 
order by date

-- Looking at total cases vs population. 
-- rolling percentage of US population infected
select location, date, total_cases, new_cases, population, total_deaths, (total_cases/population*100) as infection_rate
from CovidDeaths
where location like '%States%' and total_deaths is not null and (total_cases/population*100) > 1
order by date

--which countries have the highest infection rate
select location, max(total_cases) as highest_case_count, max((total_cases/population*100)) as infection_rate
from CovidDeaths
where (total_cases/population*100) > 1
group by location, population
order by infection_rate desc

-- Looking at death rate(deaths vs total cases)
select location, max(total_cases) as highest_case_count, max(total_deaths) as highest_death_count, population, (max(total_deaths)/max(total_cases)*100) as death_rate
from CovidDeaths
where total_deaths is not null and continent is not null 
group by location, population
order by death_rate desc



--percent of population dead
select location, population, max(cast(total_deaths as int)) highest_death_count, max((total_deaths/population*100)) as death_rate
from CovidDeaths
where total_deaths is not null and continent is not null
group by location, population
order by 1 asc

--same as above, but by continent
select location as continent, max(cast(total_deaths as int)) as highest_death_count, max(cast(total_cases as int)) as highest_case_count,
max(total_deaths/population*100) as death_rate_perc
from CovidDeaths
where total_deaths is not null and continent is null and location <> 'International' and location <> 'World'
group by location, population
order by 2 desc


--Global numbers
select location, max(total_cases) global_case_count, max(cast(total_deaths as int)) as global_death_count, max(total_deaths/total_cases*100) as death_rate
from CovidDeaths
where location = 'World' 
group by location
order by location
		--Alex the analyst way
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, round((sum(cast(new_deaths as int))/sum(new_cases)*100),2) as
death_rate
from CovidDeaths
where continent is not null and new_cases <> 0
--group by date

-- Looking at new vax per day
select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations 
from CovidDeaths dea
join CovidVaccinations vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null and vax.new_vaccinations is not null
order by 3 asc

-- rolling count per location per day
select dea.location, dea.date, vax.new_vaccinations, SUM(cast(vax.new_vaccinations as int)) 
over (partition by dea.location order by dea.date) rolling_count
from CovidDeaths dea
join CovidVaccinations vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null and vax.new_vaccinations is not null
order by 1,2

-- percent of population vaccinated
with cte_rolling_count as 
(
select dea.location, dea.population, dea.date, vax.new_vaccinations, SUM(cast(vax.new_vaccinations as int)) 
over (partition by dea.location order by dea.date) rolling_count
from CovidDeaths dea
join CovidVaccinations vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null and vax.new_vaccinations is not null
--order by 1,2
)

select location, population, max(rolling_count) total_vaccinations, (MAX(rolling_count)/population) as percent_vaxxed
from cte_rolling_count
group by location, population
order by percent_vaxxed desc


-- creating a view

create view percent_vaccinated as
with cte_rolling_count as 
(
select dea.location, dea.population, dea.date, vax.new_vaccinations, SUM(cast(vax.new_vaccinations as int)) 
over (partition by dea.location order by dea.date) rolling_count
from CovidDeaths dea
join CovidVaccinations vax
	on dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null and vax.new_vaccinations is not null
--order by 1,2
)

select location, population, max(rolling_count) total_vaccinations, (MAX(rolling_count)/population) as percent_vaxxed
from cte_rolling_count
group by location, population
--order by percent_vaxxed desc

