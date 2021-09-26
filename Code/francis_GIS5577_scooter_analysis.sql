-- Analyze escooter usage

-- Get statistics about scooter trips in 2018
-- datasets are collected in non-winter months
SELECT COUNT(tripid) as total_trips, 
AVG(tripduration)::INTEGER as avg_trip_time_secs,
AVG(tripdistance)::INTEGER as avg_trip_dist_m, 
MIN(starttime) as start_range,
MAX(starttime) as end_range,
COUNT(tripid)/(EXTRACT(MONTH FROM MAX(starttime))- EXTRACT(MONTH FROM MIN(starttime)))
FROM escooter_2018;
-- total trips: 225543
-- avg_trip_time_secs: 1127
-- avg_trip_dist_m: 2157


-- Find month with most scooter trips
WITH trips_by_date as
(
SELECT date(starttime) as start_time, COUNT(date(starttime)) as trips_per_date
FROM escooter_2018					
GROUP BY date(starttime)
ORDER BY COUNT(date(starttime)) DESC	
)
SELECT EXTRACT (MONTH FROM start_time) as trip_month, SUM(trips_per_date) as total_trips
FROM trips_by_date
GROUP BY EXTRACT(MONTH FROM start_time)	
ORDER BY EXTRACT(MONTH FROM start_time)	ASC;
--Month with most scooter trips: 10 							 
--Month with least scooter trips: 12	

							 
							 
-- Finds date with most scooter trips
SELECT date(starttime), COUNT(date(starttime)) as trips_per_date
FROM escooter_2018					
GROUP BY date(starttime)
ORDER BY COUNT(date(starttime)) DESC;
										
--Date with most trips: October 18, 2018 3694

																 
-- Which time period was the most popular (day of the week?)				
-- Returns total trips that occur on each weekday, average trip time and average trip distance for each weekday. 
SELECT to_char(starttime,'day') as "Day",		 
COUNT(tripid) as total_trips, 
AVG(tripduration)::INT as avg_trip_time, 
AVG(tripdistance)::INT as avg_trip_dist 
FROM escooter_2018
GROUP BY to_char(starttime,'day');
-- Thursdays have the most total trips in the dataset
-- Weekends have the greatest trip time and average trip distance
							 
							 
-- Get total scooter trips per hour per each weekday and average distance traveled and duration						 
CREATE TABLE escooter_activity AS
										
-- Get trip counts for each date and the day of the week										
WITH trip_occurrence as
(							 
	SELECT tripid,
	DATE(starttime) as trip_date,
	to_char(starttime, 'day') as trip_day, --get weekday name		
	EXTRACT (hour from starttime):: text as trip_hr,
	tripdistance,
	tripduration	 
	FROM escooter_2018		 
),
										
-- get total trip count for each hour of each weekday													
weekday_trips as
(
	SELECT trip_day,
	trip_hr,
	COUNT(tripid) as trip_counts,
	AVG(tripdistance)::INT as avg_trip_dist_hr,
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
	SELECT to_char(starttime, 'day') as trip_day,
	COUNT(tripid) as total
	FROM escooter_2018
	GROUP BY to_char(starttime, 'day')
	) as b					 
WHERE a.trip_day = b.trip_day;
			
							 
-- Get the percent showing portion of total scooter trips that occur for each weekday in the entire dataset	
CREATE TABLE escooter_trips_per_weekday as							 
WITH total_trips_weekday as
(
SELECT to_char(starttime, 'day') as trip_day,
COUNT(tripid) as total
FROM escooter_2018
GROUP BY to_char(starttime, 'day')
)					 
SELECT a.trip_day, (a.total/b.total_trips::FLOAT)*100 as percent_usage					 
FROM total_trips_weekday a, 
	(
		SELECT COUNT(tripid) as total_trips
		FROM escooter_2018
 	) as b
ORDER BY (a.total/b.total_trips::FLOAT)*100 DESC;

							 							 
-- Get escooter trip counts for each start centerline				 
CREATE TABLE escooter_start_streets as
WITH trip_starts as			
(							 
SELECT startcenterlineid, COUNT(startcenterlineid) as start_trips_counts
FROM escooter_2018
GROUP by startcenterlineid
)																					 
SELECT geom, m.gbsid, t.startcenterlineid, t.start_trips_counts
FROM mpls_streets m
INNER JOIN trip_starts t
ON m.gbsid::text = t.startcenterlineid
ORDER BY t.start_trips_counts DESC;
-- where did most trips start (road centerline)?
-- road segment 19563:2662

							  
-- Get counts of end trip for each unique road centerline
CREATE TABLE escooter_end_streets as
WITH trip_ends as
(
SELECT endcenterlineid, COUNT(endcenterlineid) as end_trips_counts
FROM escooter_2018
GROUP by endcenterlineid							 
)
SELECT geom, m.gbsid, e.endcenterlineid, e.end_trips_counts
FROM mpls_streets m
INNER JOIN trip_ends e
ON m.gbsid::text = e.endcenterlineid
ORDER BY e.end_trips_counts DESC;							 						
-- where did most trips end (road centerline)?
--Road segment 19437: 2272

										
--Proximity of trip start road centerlines within 0.25 mile of a transit stop									
CREATE TABLE metro_scooters as
WITH mpls_transit_stops as
(										
SELECT ST_Buffer(geography(a.geom), 1609.34) as geom
FROM metro_transitstops a, mpls_boundary b
WHERE ST_Intersects(a.geom, b.geom) 
),
metro_trips as
(										
SELECT c.gbsid, c.start_trips_counts, c.geom
FROM escooter_start_sts c, mpls_transit_stops d
WHERE ST_Intersects(c.geom, d.geom)
GROUP BY c.gbsid, c.start_trips_counts, c.geom
),
total_scooter_trips as
(
SELECT SUM(start_trips_counts) as total_trips
FROM escooter_start_streets
)							 
SELECT (SUM(a.start_trips_counts)/b.total_trips)*100 
FROM metro_trips a, total_scooter_trips b
GROUP BY b.total_trips
										
					 							 
				 