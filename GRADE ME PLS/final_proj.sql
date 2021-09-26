Maisong Francis
GIS5577: Final project code submission

--Create Table Statement x4 (5pts)  – 20 points
--The table should have indices, primary key

DROP TABLE IF EXISTS escooter_2018;

CREATE TABLE escooter_2018 (
TripID bigint,
TripDuration integer,	
TripDistance integer,	
StartTime timestamp,	
EndTime timestamp,
StartCenterlineID text,	
EndCenterlineID text,
PRIMARY KEY (TripID)
);

\COPY escooter_2018_2019 FROM 'C:\Users\msong\Desktop\proj\Data\scooter_data\escooter_2018.csv' WITH CSV Header;

--------------------------

DROP TABLE IF EXISTS nice_ride_trips_2018;

CREATE TABLE nice_ride_trips_2018
(
trip_id text,	
tripduration integer,	
start_time timestamp,	
end_time timestamp,	
start_station_id text,	
start_station_name text,	
start_station_latitude double precision, 	
start_station_longitude	double precision,
end_station_id text,
end_station_name text,	
end_station_latitude double precision,	
end_station_longitude double precision,
bikeid text,
bike_type text,
PRIMARY KEY (trip_id)
);

\COPY nice_ride_trips_2018 FROM 'C:\Users\msong\Desktop\proj\Data\niceride_data\nice_ride_trips_2018.csv' WITH CSV Header;

--------------------------

DROP TABLE IF EXISTS median_income_2018;

CREATE TABLE median_income_2018
(
geo_id text,
name text,
median_hh_income integer,
margin_of_error integer,
PRIMARY KEY (geo_id)
);

\COPY median_income_2018 FROM 'C:\Users\msong\Desktop\proj\Data\census_data\median_income\med_income_ACS_2018.csv' WITH CSV Header;

--------------------------

DROP TABLE IF EXISTS race_2018;

CREATE TABLE race_2018
(
geo_id text,	
name text,
total_pop integer,	
white_alone integer,
black_aa_alone integer,
ai_alone integer,
asian_alone integer,
nh_pi_alone integer,
other integer,
PRIMARY KEY (geo_id)
);


\COPY race_2018 FROM 'C:\Users\msong\Desktop\proj\Data\census_data\pop_race\race.csv' WITH CSV Header;

--------------------------
--SQL Query x4 – 40 points


--A SQL query that involves only 1 table.

-- Finds date with most scooter trips
SELECT date(starttime), 
COUNT(date(starttime)) as trips_per_date
FROM escooter_2018					
GROUP BY date(starttime)
ORDER BY COUNT(date(starttime)) DESC;

--------------------------

--A SQL query that involves 2 or more tables.

-- Join race and median hh income data with minneapolis census tracts
-- calculate percentage non-white
WITH mpls_tracts as
(
SELECT a.*
FROM mn_tracts a, mpls_boundary b
WHERE ST_Intersects(a.geom, b.geom)
),
race_join as
(
SELECT a.geoid, 
a.geom, 
((b.total_pop - b.white_alone)/b.total_pop::float)*100 as percent_nw
FROM mpls_tracts a
JOIN race_2018 b
ON a.geoid = b.geo_id
)
SELECT race_join.*, c.median_hh_income
FROM med_income_2018 c
JOIN race_join
ON c.geo_id = race_join.geoid

--------------------------

--A SQL query using a subquery or a common table expression

-- Get the percent showing portion of total nice ride trips that occur for each weekday in the entire dataset	
WITH total_trips_weekday as
(
SELECT to_char(start_time, 'day') as trip_day,
COUNT(trip_id) as total
FROM niceride_starts
GROUP BY to_char(start_time, 'day')
)					 
SELECT a.trip_day, (a.total/b.total_trips::FLOAT)*100 as percent_usage					 
FROM total_trips_weekday a, 
	(
		SELECT COUNT(trip_id) as total_trips
		FROM niceride_starts
 	) as b
ORDER BY (a.total/b.total_trips::FLOAT)*100 DESC;

--------------------------

--A spatial SQL query

--Proximity of nice ride trip start road centerlines within 0.25 mile of a transit stop
CREATE TABLE metro_niceride as							 
WITH mpls_transit_stops as
(										
SELECT ST_Buffer(geography(a.geom), 1609.34) as geom
FROM metro_transitstops a, mpls_boundary b
WHERE ST_Intersects(a.geom, b.geom) 
)			 
SELECT c.start_station_name, c.trip_counts, c.geom
FROM niceride_start_pts c, mpls_transit_stops d
WHERE ST_Intersects(c.geom, d.geom)
GROUP BY c.start_station_name, c.trip_counts, c.geom
