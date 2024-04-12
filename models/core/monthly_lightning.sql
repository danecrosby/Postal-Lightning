--Sums daily lighning counts in zipcodes into monthly counts
--materialized table that is paritioned by month(int64) and clustered by state and then zipcode
{{ config(
    materialized='table',
    partition_by={
      "field": "month",
      "data_type": "int64",
      "range": {
        "start": 1,
        "end": 12,
        "interval": 1
      }
    },
    cluster_by = ["state", "zip_code"]
)}}

SELECT
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    zip_code,
    city,
    state,
    SUM(number_of_strikes) AS number_of_strikes --summing lightning strikes by month
FROM
    {{ ref('daily_lightning') }}
GROUP BY
    EXTRACT(YEAR FROM date),
    EXTRACT(MONTH FROM date),
    zip_code,
    city,
    state