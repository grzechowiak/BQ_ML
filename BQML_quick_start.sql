
# DATA PREP
CREATE OR REPLACE TABLE taxirides.taxi_training_data_467 AS
WITH prep AS (
  SELECT
  pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
  ST_GEOGPOINT(pickup_latitude,pickup_longitude) AS pickout_point,
  ST_GEOGPOINT(dropoff_latitude,dropoff_longitude) AS dropoff_point,
  ST_DISTANCE(ST_GEOGPOINT(pickup_latitude,pickup_longitude), ST_GEOGPOINT(dropoff_latitude,dropoff_longitude)) as distance_in_meters,
  (tolls_amount + fare_amount) AS  fare_amount_555
  FROM `qwiklabs-gcp-00-1234e01bc028.taxirides.historical_taxi_rides_raw`
  WHERE
    trip_distance > 3
    AND fare_amount > 2
    -- AND pickup_latitude between -90 and 90
    -- AND dropoff_latitude between -90 and 90
    AND pickup_longitude > -78
  AND pickup_longitude < -70
  AND dropoff_longitude > -78
  AND dropoff_longitude < -70
  AND pickup_latitude > 37
  AND pickup_latitude < 45
  AND dropoff_latitude > 37
  AND dropoff_latitude < 45
    AND passenger_count > 3
  LIMIT 1000000
)
SELECT * FROM prep
WHERE
  distance_in_meters > 1
  AND distance_in_meters < 10000
;


# MODEL CREATE
CREATE or REPLACE MODEL taxirides.fare_model_272
OPTIONS
  (model_type='linear_reg', labels=['fare_amount_555']) AS
SELECT * EXCEPT(pickout_point, dropoff_point, distance_in_meters)
FROM
  taxirides.taxi_training_data_467
;

# EVAL
SELECT
  SQRT(mean_squared_error) AS rmse
  ,mean_squared_error AS MSE

FROM
  ML.EVALUATE(MODEL taxirides.fare_model_272,
  (
SELECT * EXCEPT(pickout_point, dropoff_point, distance_in_meters)
FROM
  taxirides.taxi_training_data_467
  ))
;


#PREDICT NEW DATA & STORE
CREATE OR REPLACE TABLE `taxirides.2015_fare_amount_predictions` AS
SELECT
*
FROM
  ml.PREDICT(MODEL taxirides.fare_model_272,
   (
    SELECT
      pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
  ST_GEOGPOINT(pickup_latitude,pickup_longitude) AS pickout_point,
  ST_GEOGPOINT(dropoff_latitude,dropoff_longitude) AS dropoff_point,
  ST_DISTANCE(ST_GEOGPOINT(pickup_latitude,pickup_longitude), ST_GEOGPOINT(dropoff_latitude,dropoff_longitude)) as distance_in_meters,
  (tolls_amount + fare_amount) AS  fare_amount_555
   FROM taxirides.report_prediction_data
   ))
