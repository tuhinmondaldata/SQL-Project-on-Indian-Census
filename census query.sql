use census
select * from census.dbo.census_data_1;

select * from census.dbo.census_data_1;

-- number of rows into our dataset
select count(*) from census..census_data_1;
select count(*) from census..census_data_2;

-- as I live in West Bengal so lets check the dataset of West Bengal
select * from census_data_1 where state in ( 'West Bengal')
select * from census_data_2 where state in ( 'West Bengal')

-- population of India
select sum(population) as 'population of India' from census..census_data_2;

--Average Growth of India
select avg(Growth)*100 as 'Average Growth of India' from census_data_1;

--Average Growth of India each state
select state, avg(Growth)*100 as 'Average Growth' from census_data_1 group by state ;

--Average sex ratio
select state, round(avg(Sex_Ratio),0) as 'Average sex ratio' from census_data_1 group by state order by 'Average sex ratio' desc;

--Average Literacy rate
select state, round(avg(Literacy),3) as 'Average Literacy rate' from census_data_1 group by state order by 'Average Literacy rate' desc;

-- top 3 state showing highest growth ratio
select top 3 state, avg(Growth)*100 as 'Top 3 growing state' from census_data_1 group by state order by 'Top 3 growing state' desc ;

--bottom 3 state showing lowest sex ratio
select top 3 state,round(avg(sex_ratio),0) as 'Lowest 3 sex ratio state' from census_data_1 group by state order by 'Lowest 3 sex ratio state' asc;

-- top and bottom 3 states in literacy state
drop table if exists #topstates;
create table #topstates
( state nvarchar(255),
  topstate float

  )

insert into #topstates
select state,round(avg(literacy),0) avg_literacy_ratio from census_data_1
group by state order by avg_literacy_ratio desc;

select top 3 * from #topstates order by #topstates.topstate desc;

drop table if exists #bottomstates;
create table #bottomstates
( state nvarchar(255),
  bottomstate float

  )

insert into #bottomstates
select state,round(avg(literacy),0) avg_literacy_ratio from census_data_1
group by state order by avg_literacy_ratio desc;
select top 3 * from #bottomstates order by #bottomstates.bottomstate asc;

--union opertor

select * from (
select top 3 * from #topstates order by #topstates.topstate desc) a

union

select * from (
select top 3 * from #bottomstates order by #bottomstates.bottomstate asc) b;

-- states starting with letter a

select distinct state from census_data_1 where lower(state) like 'a%' or lower(state) like 'b%'

select distinct state from census_data_1 where lower(state) like 'a%' and lower(state) like '%m'

-- joining both table

--total males and females
-- Here I have calculated this by
--female/male = sex ratio.....1
--female+male = population......2
--female= population-male......3
--population-male=sex ratio*male
--population=males(sex ratio+1)
--males= population/(sex ratio+1)
--females= population- population/(sex ratio+1)
--=population(1-1/(sex ratio+1))
--=(population*(sex ratio)/(sex ratio+1)

select d.state,sum(d.males) total_males,sum(d.females) total_females from
(select c.district, c.state, round(c.population/(c.sex_ratio+1),0) males, round((c.population*c.sex_ratio)/(c.sex_ratio+1),0) females from
(select a.district, a.state, a.sex_ratio/1000 sex_ratio, b.population from census_data_1 
a inner join census_data_2 b on a.District=b.District)c)d group by d.state;


--  total_literate_people and total_illiterate_people

-- Here I have calculated this by
--total literate people/population= literacy ratio
--total literate people=literacy ratio * population
--total illterate people=( 1-literacy ratio)*population

select d.state, sum(d.literate_people) total_literate_people, sum(d.illiterate_people) total_illiterate_people from
(select c.district, c.state, round(c.literacy_ratio*c.population,0) literate_people, round((1-c.literacy_ratio)*c.population,0) illiterate_people from
(select a.district, a.state, a.literacy/100 literacy_ratio, b.population from census_data_1
a inner join census_data_2 b on a.district=b.district)c)d group by d.state;



-- population in previous census


-- Here I have calculated this by
--previous_census + growth*previous_census= population
--previous_census= population/(1+growth)


select sum(e.previous_census_population) previous_census_population,sum(e.current_census_population) current_census_population from(
select d.state,sum(d.previous_census_population) previous_census_population,sum(d.current_census_population) current_census_population from
(select c.district,c.state,round(c.population/(1+c.growth),0) previous_census_population,c.population current_census_population from
(select a.district,a.state,a.growth growth,b.population from census_data_1 a inner join census_data_2 b on a.district=b.district)c) d
group by d.state)e


-- population vs area

select (j.total_area/j.previous_census_population)  as previous_census_population_vs_area, (j.total_area/j.current_census_population) as 
current_census_population_vs_area from(

select h.*, i.total_area from(

select '1' as 'keyy' , f.* from
(select sum(e.previous_census_population) previous_census_population,sum(e.current_census_population) current_census_population from(
select d.state,sum(d.previous_census_population) previous_census_population,sum(d.current_census_population) current_census_population from
(select c.district,c.state,round(c.population/(1+c.growth),0) previous_census_population,c.population current_census_population from
(select a.district,a.state,a.growth growth,b.population from census_data_1 a inner join census_data_2 b on a.district=b.district)c) d
group by d.state)e) f) h inner join (


select '1' as 'keyy', g.* from
(select sum(Area_km2) total_area from census_data_2)g)i on h.keyy= i.keyy)j


--window function
--output top 3 districts from each state with highest literacy rate


select a.* from
(select district,state,literacy,rank() over(partition by state order by literacy desc) rnk from census_data_1) a

where a.rnk in (1,2,3) order by state