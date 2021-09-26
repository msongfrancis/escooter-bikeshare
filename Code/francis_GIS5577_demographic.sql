-- Join race and median hh income data with minneapolis census tracts
-- calculate percentage non-white
CREATE TABLE demographics as
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
