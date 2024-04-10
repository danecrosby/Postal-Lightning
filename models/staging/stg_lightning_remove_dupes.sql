{{
    config(
        materialized='view'
    )
}}

WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY date, number_of_strikes, ST_ASTEXT(center_point_geom) ORDER BY (SELECT NULL)) AS row_num
    FROM {{ source('staging','lightning_2021') }}
)
SELECT date, number_of_strikes, center_point_geom
FROM CTE
WHERE row_num = 1
