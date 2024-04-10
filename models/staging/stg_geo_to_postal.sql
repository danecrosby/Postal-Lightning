{{
    config(
        materialized='view'
    )
}}

-- making some changes to column names
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
  ST_CONTAINS(ST_GeogFromText(z.zipcode_geom) , l.center_point_geom) --if the center point lies within the postal code dimensions
ORDER BY date, state, zip_code