{{
    config(
        materialized='view'
    )
}}
--this is the heart of the transformation, it takes NOAA's lightning data which grouped into 0.1 x 0.1 degree tiles (roughly 11 Km^2) and determines which postal codes hold those centerpoints
--I use ST_CONTAINS for this, but something like ST_OVERLAPS would probably be better for more accuracy and would solve the issue where some smaller zipcodes are ignored completely
--ST_OVERLAPS https://postgis.net/docs/ST_Overlaps.html
--ST_CONTAINS https://postgis.net/docs/ST_Contains.html

-- changing zipcode to zip_code so it matches other columns
SELECT 
  z.zipcode as zip_code,
  z.city as city,
  z.state_name as state,
  l.number_of_strikes as number_of_strikes,
  l.center_point_geom as center_point_geom,
  l.date as date
FROM 
  {{ source('staging','zipcodes') }} z,
  {{ ref('stg_lightning_remove_dupes') }} l
WHERE 
  ST_CONTAINS(ST_GeogFromText(z.zipcode_geom) , l.center_point_geom) --if the center point of strike data lies within the postal code dimensions then join
ORDER BY date, state, zip_code