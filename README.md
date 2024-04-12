# Postal-Lightning
Mapping lightning strikes geo data to US Postal codes

This project takes lightning stike from the [NOAA Cloud-to-Ground Lightning Strikes](https://console.cloud.google.com/bigquery(cameo:product/noaa-public/lightning)?project=geo-lightning&ws=!1m0) which is daily lightning strikes aggregated into 0.1 x 0.1 degree tiles, sized roughly 11 km^2, and tries to map that data onto US postal codes by determining which of these tiles fall into which postal code area. It uses the [ST_CONTAINS() function](https://postgis.net/docs/ST_Contains.html) and postal code geographical polygon data from the zipcodes table map the tiles onto complex polygonal postal codes. 
***Important Note**: in the US the terms Zip Code and Postal Code are used interchangeably.*


# Workflow Orchestration
Using dbt Cloud to create a pipeline of tables in BigQuery. The pipleline looks like this:
![IDE-dbt-Cloud](https://github.com/danecrosby/Postal-Lightning/assets/59389278/c2d746ea-deab-4e59-bcf7-fa3c408c3a51)

## key
- ### source models
  - **staging.lightning_2021** - raw data from NOAA from the year 2021, consists of date, number_of_strikes, and the GEOGRAPHY type center point for each 0.1 x 0.1 degree tile.
  - **staging.zipcodes** - zipcodes and their corresponding geometry data represented as a polygon. also has state, county, and city data.
  - **staging.states** - all 50 states, formatted as "California", "Arizona", "Washington", etc
- ### staging models
  - **stg_lightning_remove_dupes** - the raw data from NOAA is extremely redundant, most of it is duplicates so we remove them first to reduce space and computation.
  - **stg_geo_to_postal** - the core of computation is here. This uses the [ST_CONTAINS() function](https://postgis.net/docs/ST_Contains.html) on a of the join lightning_2021 table to zipcodes table, keeping rows where the geo data falls lies with postal/zip code polygons.
- ### core models
  - **stg_lightning_remove_dupes** - the raw data from NOAA is extremely redundant, most of it is duplicates so we remove them first to reduce space and computation.
  - **stg_geo_to_postal** - 


