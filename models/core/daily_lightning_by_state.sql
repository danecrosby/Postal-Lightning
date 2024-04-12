--Sums daily lighning counts by state and day
--materialized table that is paritioned by month(timestamp) and clustered by state and then date(day)
{{ config(
    materialized='table',
    partition_by={
      "field": "date",
      "data_type": "timestamp",
      "granularity": "month"
    },
    cluster_by = ["state", "date"]
)}}

SELECT
    date,
    state,
    SUM(number_of_strikes) AS number_of_strikes --summing lightning strikes by state
FROM
    {{ ref('daily_lightning') }}
GROUP BY
    date,
    state