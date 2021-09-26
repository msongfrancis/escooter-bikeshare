-- create tables and load data

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
--IGNORE/DELETE
--psql -h 129.114.17.71 -d leex6165 -U leex6165 -p 5432 -f C:\Users\msong\Desktop\proj1\Data\niceride_data\create_niceride_table.sql
--psql -h 129.114.17.71 -d leex6165 -U leex6165 -p 5432 -f C:\Users\msong\Desktop\proj1\Data\scooter_data\create_escooter_table.sql
--psql -h 129.114.17.71 -d leex6165 -U leex6165 -p 5432 -f C:\Users\msong\Desktop\proj1\Data\census_data\create_race_table.sql
--psql -h 129.114.17.71 -d leex6165 -U leex6165 -p 5432 -f C:\Users\msong\Desktop\proj1\Data\census_data\create_med_income_table.sql
--------------------------