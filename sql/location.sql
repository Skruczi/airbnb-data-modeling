CREATE TABLE airbnb.locations (
    listing_id BIGINT PRIMARY KEY REFERENCES airbnb.listings(listing_id),

    neighbourhood TEXT,
    neighbourhood_cleansed TEXT,
    neighbourhood_group_cleansed TEXT,

    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

INSERT INTO airbnb.locations
SELECT
    listing_id,
    neighbourhood,
    neighbourhood_cleansed,
    neighbourhood_group_cleansed,
    latitude,
    longitude
FROM airbnb.stg_listings;

ALTER TABLE airbnb.locations
ALTER COLUMN listing_id SET NOT NULL;


-- exploring
SELECT *
FROM airbnb.locations
WHERE neighbourhood_group_cleansed IS NOT NULL;

-- dropping useless column
ALTER TABLE airbnb.locations
DROP COLUMN neighbourhood_group_cleansed;
