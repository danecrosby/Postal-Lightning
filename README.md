# Postal-Lightning
This project maps NOAA's lightning strike geo data onto US Postal codes. Geographical data is interesting, but doesn't tell us which postal code, county, city, or state that lightning is hitting. This project takes takes that geographical data and turns it into postal code data so it can be analyzed in a number of different ways. It also greatly reduces the size of the data for easy dashboarding.

### How it works
This project uses 2021's US lightning stike data from [NOAA Cloud-to-Ground Lightning Strikes](https://console.cloud.google.com/bigquery(cameo:product/noaa-public/lightning)?project=geo-lightning&ws=!1m0), daily lightning strikes aggregated into 0.1 x 0.1 degree tiles, sized roughly 11 km^2, and maps that data onto US postal codes by determining which of these tiles falls into which postal code area. It uses the `ST_CONTAINS()` [function](https://postgis.net/docs/ST_Contains.html) and the polygon from the zipcodes table and calculates if the center of the NOAA tiles lies in the postal code's polygon.

***Important Note**: in the US the terms Zip Code and Postal Code are used interchangeably.*

## Tools used
- BigQuery (Data Warehouse)
- dbt Cloud (Orchestration and Transformation)
- Looker Studio (Dashboard)

# Workflow Orchestration
Using dbt Cloud to create a pipeline of tables in BigQuery. The pipleline looks like this:
![IDE-dbt-Cloud](https://github.com/danecrosby/Postal-Lightning/assets/59389278/c2d746ea-deab-4e59-bcf7-fa3c408c3a51)
- ### source models
  - **staging.lightning_2021** - raw data from NOAA from the year 2021, consists of date, number_of_strikes, and the GEOGRAPHY type center point for each 0.1 x 0.1 degree tile.
  - **staging.zipcodes** - zipcodes and their corresponding geometry data represented as a polygon. also has state, county, and city data.
  - **staging.states** - all 50 states, formatted as "California", "Arizona", "Washington", etc
- ### staging models (unmaterialized)
  - **stg_lightning_remove_dupes** - the raw data from NOAA is extremely redundant, most of it is duplicates so we remove them first to reduce space and computation.
  - **stg_geo_to_postal** - most of the computation happens here. This uses the `ST_CONTAINS()` [function](https://postgis.net/docs/ST_Contains.html) on a join of the lightning_2021 table and zipcodes table selecting rows where the geo data lies within postal code polygons. Even though the code is relatively simple this costs a lot to run with BigQuery, so make sure to test with smaller datasets first.
  - **stg_group_by_zipcode** - some postal codes are large and will have multiple tiles within them. This bins the tiles, summing the number_of_strikes and grouping by postal code.
- ### core models (materialized)
  - **daily_lightning** - lightning strikes per zipcode per day (large table, too large for Looker Studio, so I have created other summed tables below)
  - **daily_lightning_by_state** - lightning strikes per state per day
  - **monthly_lightning** - lightning strikes per zipcode per month

# Data Warehouse
## BigQuery
After building and running the workflow in dbt Cloud your views and tables should look like this

![BigQuery tables](https://github.com/danecrosby/Postal-Lightning/assets/59389278/5adeec68-2b87-41fa-821f-8c30c77cac2d)

## Clustering and Paritioning of core models
### These three tables are materialized because they will be accessed by Looker Studio.
They are paritioned by month because by Looker Studio dashboard has monthly filters because lightning data and weather patterns become more interesting when viewed monthly. Clustering happens by state and then date. Clustering by state because the next important filter I use in the dashboard is the state filter. Lastly the clustering by date makes sense because every graph and map uses the date dimension and ordering chronologically should make those, esepcially graphs over time, faster and more efficient. One exception is the **monthly_lightning** table, which is partitioned by a month integer and therefore has no date dimension to cluster by, so I clustered by zipcode instead which might help if I wanted to list entries by zipcode.

daily_lightning            |  daily_lightning_by_state |  monthly_lightning
:-------------------------:|:-------------------------:|:-------------------------:
![daily_lightning](https://github.com/danecrosby/Postal-Lightning/assets/59389278/ab3703ea-4f05-4cf1-b9f0-a16c2caf1777)  |  ![daily_by_states](https://github.com/danecrosby/Postal-Lightning/assets/59389278/202773c4-d9ea-4682-a68e-1515630bd1e0) | ![monthly_lightning](https://github.com/danecrosby/Postal-Lightning/assets/59389278/5fbefcd8-5495-43d1-b2c6-cb6cb0c91ea1)

# Transformations
All transformations are defined using dbt which dbt cloud compiles into BigQuery compatible SQL. Below is an example of how paritioning and clustering format looks in dbt as well as how tables are referenced as in the FROM and JOIN statement.
```sql
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
```
# Dashboards
### [2021 US Lightning Heatmap Dashboard](https://lookerstudio.google.com/reporting/2bd2b75f-fde4-4acf-8cd4-e8e2434a88d7/page/XxCwD) - *can take several seconds to load*
<img src="https://github.com/danecrosby/Postal-Lightning/assets/59389278/a4fb4cc2-fda5-441d-bb65-b5f895fd2892" width="60%" height="60%">

*Controllable fields are State and Month*

### [2021 Lightning Filled Map Dashboard](https://lookerstudio.google.com/reporting/88e6e66d-e14c-41c2-85d8-8cea759d8a75/page/cnzwD) - *state by state*
<img src="https://github.com/danecrosby/Postal-Lightning/assets/59389278/3019f5c7-015c-4dd5-8c4b-315e93fe52f9" width="60%" height="60%">

*hover over filled areas for additional lightning strike and city info*

# How to run
- Fork the code into your own repository and connect dbt Cloud to your GitHub account. Instructions on how to do that here: https://docs.getdbt.com/docs/cloud/git/connect-github
- Then link dbt Cloud to BigQuery or other data warehouse. Instructions here: https://docs.getdbt.com/guides/bigquery?step=1
- You can then extract data from NOAA's lighting grid map from https://console.cloud.google.com/bigquery(cameo:product/noaa-public/lightning)?project=geo-lightning&ws=!1m0 . I don't reccomend sampling more than 1 year's worth since the entire table is 5.5 terabytes large.
- Make sure to alter the schema.yml file in staging folder to fit your own BigQuery database. For example mine looks like:
  ```yml
  sources:
  - name: staging
    database: geo-lightning
    schema: lightning_strikes

    tables:
      - name: lightning_2021 #raw lightning data in the US for 2021 taken from NOAA's bigquery table https://console.cloud.google.com/bigquery(cameo:product/noaa-public/lightning)?project=geo-lightning
      - name: zipcodes #geometry data for each zipcode
      - name: states #list of all 50 US States
  ```





