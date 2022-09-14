select *
From PortfolioProject..CovidDeaths
order by 3,4

-- select *
-- From PortfolioProject..CovidVaccinations
-- order by 3,4

-- Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

-- Looking at total cases vs population
Select location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2

-- Looking at countries with highest infection rate compared to population
Select location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as CovidPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by location, population
order by CovidPercentage desc

-- Looking countries with highest death count per population
Select location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not NULL
Group by location
order by TotalDeathCount desc

-- Break it down by continent
Select location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is NULL
and location not like '%High income%'
and location not like '%Upper middle income%'
and location not like '%Lower middle income%'
and location not like '%Low income%'
Group by location
order by TotalDeathCount desc

-- Global Numbers
Select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not NULL
Group by date
order by 1,2

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not NULL
order by 1,2


-- Looking at total population vs vaccination

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac 
    On dea.location = vac.location 
    and dea.date = vac.date
Where dea.continent is not NULL
and new_vaccinations is not NULL
order by 2,3

-- USE CTE
With PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac 
    On dea.location = vac.location 
    and dea.date = vac.date
Where dea.continent is not NULL
and new_vaccinations is not NULL
--order by 2,3  
)
Select *, (RollingPeopleVaccinated/population)*100 as PercentPeopleVaccinated
From PopvsVac

-- Create view to store data for later visualizations

Create View PercentPeopleVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac 
    On dea.location = vac.location 
    and dea.date = vac.date
Where dea.continent is not NULL 
and new_vaccinations is not NULL
--order by 2,3

Select *
From PercentPeopleVaccinated