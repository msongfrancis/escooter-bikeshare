-- Analyze nice ride usage
							 
--Create point features for nice ride start locations			
CREATE TABLE niceride_starts AS 
TABLE nice_ride_trips_2018;

ALTER TABLE niceride_starts ADD COLUMN geom geometry(Point, 4326);
UPDATE niceride_starts SET geom = ST_SetSRID(ST_MakePoint(start_station_longitude, start_station_latitude), 4326);							 


--Create points for nice ride end locations						 
CREATE TABLE niceride_ends AS 
TABLE nice_ride_trips_2018;

ALTER TABLE niceride_ends ADD COLUMN geom geometry(Point, 4326);
UPDATE niceride_ends SET geom = ST_SetSRID(ST_MakePoint(end_station_longitude, end_station_latitude), 4326);									 
							 

-- Get total trip count
SELECT COUNT(trip_id) as total_trips, 
AVG(tripduration)::INTEGER as avg_trip_time_secs,
MIN(start_time) as start_range,
MAX(start_time) as end_range,
COUNT(trip_id)/(EXTRACT(MONTH FROM MAX(start_time))- EXTRACT(MONTH FROM MIN(start_time))) as monthly_avg_trips
FROM niceride_starts

-- total trips: 824846
-- average trip time: 3825
-- date range: 04/12/2018 - 11/17/2018


--find counts of nice ride trips per date
SELECT date(start_time) as start_time, COUNT(date(start_time)) as trips_per_date
FROM niceride_starts
GROUP BY date(start_time)
ORDER BY COUNT(date(start_time)) DESC	
-- date with most trips: 07/21/2018
										
										
-- find counts of nice ride trips per month
WITH trips_by_date as
(
SELECT date(start_time) as start_time, COUNT(date(start_time)) as trips_per_date
FROM niceride_starts
GROUP BY date(start_time)
ORDER BY COUNT(date(start_time)) DESC	
)										
SELECT EXTRACT (MONTH FROM start_time) as trip_month, SUM(trips_per_date) as total_trips
FROM trips_by_date
GROUP BY EXTRACT(MONTH FROM start_time)	
ORDER BY EXTRACT(MONTH FROM start_time)	ASC;										
--Month with most nice ride trips: 7							 
--Month with least nice ride trips: 11

							 
-- Which day of the week did trips typically occur				
-- Returns total nice ride trips that occur on each weekday and average trip time for each weekday. 
SELECT to_char(start_time,'day') as "Day",		 
COUNT(trip_id) as total_trips, 
AVG(tripduration)::INT as avg_trip_time 
FROM niceride_starts
GROUP BY to_char(start_time,'day');
-- Fridays had most trips
-- Tuesdays had the least trips

							 
-- Get total nice ride trips per hour per each weekday and average time traveled 					 
CREATE TABLE niceride_activity AS							 
WITH trip_occurrence as
(	
-- Get trip counts for each date and the day of the week
	SELECT trip_id,
	DATE(start_time) as trip_date,
	to_char(start_time, 'day') as trip_day, --get week day name		
	EXTRACT (hour from start_time):: text as trip_hr,
	tripduration	 
	FROM niceride_starts		 
),
-- get total trip count for each hour of each weekday							 
weekday_trips as
(	
	SELECT trip_day,
	trip_hr,
	COUNT(trip_id) as trip_counts,
	AVG(tripduration)::INT as avg_trip_dur_hr
	FROM trip_occurrence
	GROUP BY (trip_day||' '||trip_hr), trip_day, trip_hr
	ORDER BY trip_day
)
-- get percent of activity for each hour of each weekday							 
SELECT a.*, 
b.total, 
-- divide trip counts for each hour of a certain weekday by the total trips for that weekday
-- computes percentage of activity for that weekday in the specified hour							 
(a.trip_counts/b.total::FLOAT)*100 as usage_percentage 
FROM weekday_trips a, 																								 
(
	SELECT to_char(start_time, 'day') as trip_day,
	COUNT(trip_id) as total
	FROM niceride_starts
	GROUP BY to_char(start_time, 'day')
) as b					 
WHERE a.trip_day = b.trip_day;							 
							 
							 
-- Get the percent showing portion of total nice ride trips that occur for each weekday in the entire dataset	
CREATE TABLE niceride_trips_per_weekday as							 
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

							 
							 
-- get trip counts for each start niceride trip location
-- if start station is null, it was a dockless trip. 		
CREATE VIEW niceride_start_pts as							 
SELECT start_station_name, COUNT(geom) as trip_counts, geom
FROM niceride_starts
GROUP BY start_station_name, geom 
ORDER BY start_station_name DESC
	
-- get trip counts for each end niceride trip location	
CREATE VIEW niceride_end_pts as									 
SELECT end_station_name, COUNT(geom) as trip_counts, geom
FROM niceride_ends
GROUP BY end_station_name, geom 
ORDER BY end_station_name DESC	
							 
							 
--Proximity of trip start road centerlines within 0.25 mile of a transit stop
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
	
							 
							 
--compute percentage of trips within 0.25 of a transit stop								 
WITH mpls_transit_stops as
(										
SELECT ST_Buffer(geography(a.geom), 1609.34) as geom
FROM metro_transitstops a, mpls_boundary b
WHERE ST_Intersects(a.geom, b.geom) 
),
metro_trips as
(					 
SELECT c.start_station_name, c.trip_counts, c.geom
FROM niceride_start_pts c, mpls_transit_stops d
WHERE ST_Intersects(c.geom, d.geom)
GROUP BY c.start_station_name, c.trip_counts, c.geom
), 
total_niceride_trips as
(
SELECT SUM(trip_counts) as total_trips
FROM niceride_start_pts
)							 
SELECT (SUM(a.trip_counts)/b.total_trips)*100 
FROM metro_trips a, total_niceride_trips b
GROUP BY b.total_trips
