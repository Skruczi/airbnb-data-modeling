CREATE TABLE airbnb.availability (
    listing_id BIGINT PRIMARY KEY REFERENCES airbnb.listings(listing_id),

    has_availability BOOLEAN,

    availability_30 INT,
    availability_60 INT,
    availability_90 INT,
    availability_365 INT,

    availability_eoy INT,
    calendar_last_scraped DATE
);

INSERT INTO airbnb.availability
SELECT
    listing_id,
    has_availability,
    availability_30,
    availability_60,
    availability_90,
    availability_365,
    availability_eoy,
    calendar_last_scraped
FROM airbnb.stg_listings;

ALTER TABLE airbnb.availability
ALTER COLUMN listing_id SET NOT NULL;


-- exploring
SELECT *
FROM airbnb.availability
WHERE has_availability IS NULL;

-- fixing has_availability column
UPDATE airbnb.availability
SET has_availability =
    CASE
        WHEN availability_365 > 0 THEN TRUE
        ELSE FALSE
    END;

-- grouping by availability
SELECT has_availability, COUNT(*)
FROM airbnb.availability
GROUP BY has_availability;


-- creating occupancy rate column
ALTER TABLE airbnb.availability
ADD COLUMN occupancy_rate NUMERIC(5,4);
UPDATE airbnb.availability
SET occupancy_rate = 1 - (availability_365 / 365.0);

-- availability_ratio_short_term
ALTER TABLE airbnb.availability
ADD COLUMN availability_30_ratio NUMERIC(5,4);
UPDATE airbnb.availability
SET availability_30_ratio = availability_30 / 30.0;

-- consistency check
SELECT COUNT(*)
FROM airbnb.availability
WHERE availability_30 > availability_60
   OR availability_60 > availability_90
   OR availability_90 > availability_365;
   
SELECT COUNT(*)
FROM airbnb.availability
WHERE availability_30 IS NULL
	OR availability_60 IS NULL
	OR availability_90 IS NULL
	OR availability_365 IS NULL;

-- constraints for consistency
ALTER TABLE airbnb.availability
ADD CONSTRAINT availability_30_range CHECK (availability_30 BETWEEN 0 AND 30);

ALTER TABLE airbnb.availability
ADD CONSTRAINT availability_60_range CHECK (availability_60 BETWEEN 0 AND 60);

ALTER TABLE airbnb.availability
ADD CONSTRAINT availability_90_range CHECK (availability_90 BETWEEN 0 AND 90);

ALTER TABLE airbnb.availability
ADD CONSTRAINT availability_365_range CHECK (availability_365 BETWEEN 0 AND 365);

-- cleaning
SELECT calendar_last_scraped, COUNT(*)
FROM airbnb.availability
GROUP BY calendar_last_scraped; -- seems like this column is useless

ALTER TABLE airbnb.availability
DROP COLUMN calendar_last_scraped;