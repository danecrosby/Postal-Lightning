--some zipcodes have multiple geom_center_points in them due to their large size. these can be combined by summing lightning strike counts and discarding the geo data
{{
    config(
        materialized='view'
    )
}}

SELECT 
    zip_code,
    city,
    state,
    SUM(number_of_strikes) AS number_of_strikes,
    date
FROM 
    {{ ref('stg_geo_to_postal') }}
GROUP BY 
    zip_code,
    city,
    state,
    date
ORDER BY  
    zip_code,
    state,
    date