Use CovidProject

Select *
From CovidDeaths

-- Tính % người mất do nhiễm bệnh Covid (có thể lấy 2 chữ số phần thập phân):
-- Xem % người mất tại Việt Nam:
Select location, date, total_cases, total_deaths, (Format(Convert(float, total_deaths) / Nullif(Convert(float, total_cases), 0) * 100, 'N2')) As DeathPercentage
From CovidDeaths
Where location = 'Vietnam'
Order By 1, 2

-- Tính % dân số bị nhiễm Covid:
Select location, date, population, total_cases, total_deaths
	, FORMAT(
				(NULLIF(Convert(float, total_cases), 0) / population) * 100
				, 'N2'
			) AS InfectedPercentage
From CovidDeaths
--Where location = 'Vietnam'
Order By 1, 2

-- Xem các quốc gia có tỉ lệ bị nhiễm bệnh so với dân số của các quốc gia đó:
-- Thông tin bao gồm: location, population, total_cases max (HighestInfection), InfectedPercentage max.
Select location, population, date, Max(Convert(float, total_cases)) as HighestInfection, Max(FORMAT(
				(NULLIF(Convert(float, total_cases), 0) / population) * 100, 'N2')) AS InfectedPercentage
From CovidDeaths
Group By location, population, date
Order By InfectedPercentage desc

-- Xem các quốc gia có số người tử vong cao so với dân số các quốc gia đó:
Select location, Max(Convert(float, total_deaths)) as HighestDeath
From CovidDeaths
Where continent is not null
Group By location
Order By HighestDeath desc

Select location, Max(Convert(float, total_deaths)) as HighestDeath
From CovidDeaths
Where continent is null
Group By location
Order By HighestDeath desc

-- Thống kê từng lục địa có số ca tử vong cao nhất:
Select continent, Max(Convert(float, total_deaths)) as HighestDeath
From CovidDeaths
Where continent is not null
Group By continent
Order By HighestDeath desc

-- Thống kê tổng số ca nhiễm bệnh, tổng số ca tử vong và tỉ lệ tử vong theo ngày:
Select date, Sum(new_cases) as NewTotalCases, Sum(new_deaths) as NewTotalDeaths, 
		Case
			When Sum(new_cases) != 0 then Format((Sum(new_deaths) / Sum(new_cases)) * 100, 'N2')
			Else NULL
		End as DeathPercentage
From CovidDeaths
Where continent is not null
Group By date
Order By date, NewTotalCases

Select Sum(new_cases) as NewTotalCases, Sum(new_deaths) as NewTotalDeaths, 
		Case
			When Sum(new_cases) != 0 then Format((Sum(new_deaths) / Sum(new_cases)) * 100, 'N2')
			Else NULL
		End as DeathPercentage
From CovidDeaths
Where continent is not null
--Group By date
Order By total_cases, total_deaths

Select *
From CovidVaccinations

-- Xem thông tin bảng con từ 2 bảng CovidDeaths và CovidVaccinations dựa vào location và date:
Select *
From CovidDeaths d
Inner Join CovidVaccinations v
	On d.location = v.location
	and d.date = v.date

-- Xem thông tin dân số và số người tiêm vaccine:
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
		, Sum(Convert(float, v.new_vaccinations))
		Over(Partition By d.location Order By d.location, d.date) as TotalVaccinated
		-- đối với dòng trên có ý nghĩa là tính tổng số người tiêm vaccine mới theo từng location (partition by) và 
		-- sau đó sắp xếp theo thứ tự (order by) của location và date để cộng dồn người tiêm vaccine mới theo từng thời gian và địa điểm.
From CovidDeaths d
Inner Join CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
Where d.continent is not null
Order By 2, 3

With PopVsVac (continent, location, date, population, new_vaccinations, TotalVaccinated)
As
(
	Select d.continent, d.location, d.date, d.population, v.new_vaccinations
		, Sum(Convert(float, v.new_vaccinations))
		Over(Partition By d.location Order By d.location, d.date) as TotalVaccinated
		-- đối với dòng trên có ý nghĩa là tính tổng số người tiêm vaccine mới theo từng location (partition by) và 
		-- sau đó sắp xếp theo thứ tự (order by) của location và date để cộng dồn người tiêm vaccine mới theo từng thời gian và địa điểm.
	From CovidDeaths d
	Inner Join CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
	--Where d.continent is not null
	--Order By 2, 3
)
Select *, Format((TotalVaccinated / population) * 100, 'N2') as VacPercentage
From PopVsVac

-- Tạo bảng mới thống kê số lượng tiêm vaccine mới và tỉ lệ tiêm vaccine so với dân số ở Việt Nam:
Drop Table if exists VaccinatedInVN
Create Table VaccinatedInVN
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	TotalVaccinated numeric,
);

Insert Into VaccinatedInVN
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
		, Sum(Convert(float, v.new_vaccinations))
		Over(Partition By d.location Order By d.location, d.date) as TotalVaccinated
		-- Đối với dòng trên có ý nghĩa là tính tổng số người tiêm vaccine mới theo từng location (partition by)
		-- Sau đó sắp xếp theo thứ tự (order by) của location và date để cộng dồn người tiêm vaccine mới theo từng thời gian và địa điểm.
From CovidDeaths d
Inner Join CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
Where d.continent = 'Vietnam';

Select *, Format((TotalVaccinated / population) * 100, 'N2') as VacPercentage
From VaccinatedInVN

-- Tạo bảng mới thống kê số lượng tiêm vaccine mới và tỉ lệ tiêm vaccine so với dân số ở Châu Á:
Drop Table if exists VaccinatedInAsia
Create Table VaccinatedInAsia
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	TotalVaccinated numeric,
);

Insert Into VaccinatedInAsia
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
		, Sum(Convert(float, v.new_vaccinations))
		Over(Partition By d.location Order By d.location, d.date) as TotalVaccinated
		-- Đối với dòng trên có ý nghĩa là tính tổng số người tiêm vaccine mới theo từng location (partition by)
		-- Sau đó sắp xếp theo thứ tự (order by) của location và date để cộng dồn người tiêm vaccine mới theo từng thời gian và địa điểm.
From CovidDeaths d
Inner Join CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
Where d.continent = 'Asia';

Select *, Format((TotalVaccinated / population) * 100, 'N2') as VacPercentage
From VaccinatedInAsia

-- Tạo Views để lưu trữ dữ liệu để biểu diễn:
Create View VacPercentage as
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
		, Sum(Convert(float, v.new_vaccinations))
		Over(Partition By d.location Order By d.location, d.date) as TotalVaccinated
		-- đối với dòng trên có ý nghĩa là tính tổng số người tiêm vaccine mới theo từng location (partition by) và 
		-- sau đó sắp xếp theo thứ tự (order by) của location và date để cộng dồn người tiêm vaccine mới theo từng thời gian và địa điểm.
From CovidDeaths d
Inner Join CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
Where d.continent is not null

Select *
From VacPercentage
