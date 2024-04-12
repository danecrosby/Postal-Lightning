--takes lightning grouped by zipcode and removes zipcodes that have invalid/NULL states
--materialized table that is paritioned by month(timestamp) and clustered by state and then date(daily)
    materialized='table',
    partition_by={
      "field": "date",
      "data_type": "timestamp",
      "granularity": "month"
    },
    cluster_by = ["state", "date"]
)}}

SELECT
    t.date,
    t.zip_code,
    t.city,
    t.state,
    t.number_of_strikes
FROM
  {{ ref('stg_group_by_zipcode') }} t
JOIN
  {{ source('staging','states') }} s --50 States written as strings as "California", "Alabama", "Texas", etc
ON
  t.state = s.state --This removes zipcodes that don't have states assigned or are split across two or more states