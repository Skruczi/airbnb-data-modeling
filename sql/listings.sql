CREATE TABLE airbnb.listings (
    listing_id BIGINT PRIMARY KEY,
    host_id BIGINT REFERENCES airbnb.hosts(host_id),

    name TEXT,
    description TEXT,

    property_type TEXT,
    room_type TEXT,

    accommodates INT,
    bedrooms INT,
    beds INT,
    bathrooms NUMERIC(3,1),

    price NUMERIC(10,2),

    minimum_nights INT,
    maximum_nights INT,

    instant_bookable BOOLEAN,
    license TEXT,

    amenities JSON
);

INSERT INTO airbnb.listings
SELECT
    listing_id,
    host_id,
    name,
    description,
    property_type,
    room_type,
    accommodates,
    bedrooms,
    beds,
    bathrooms,
    price,
    minimum_nights,
    maximum_nights,
    instant_bookable,
    license,
    amenities
FROM airbnb.stg_listings;

-- cheking ID uniqueness
SELECT COUNT(*)
FROM airbnb.listings
WHERE host_id IS NULL;

SELECT COUNT(*), COUNT(DISTINCT host_id)
FROM airbnb.listings;

SELECT COUNT(*), COUNT(DISTINCT host_id)
FROM airbnb.hosts;

ALTER TABLE airbnb.listings
ALTER COLUMN listing_id SET NOT NULL;

ALTER TABLE airbnb.listings
ALTER COLUMN host_id SET NOT NULL;

SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_name = 'listings'
AND column_name = 'host_id';

-- price column name fix
ALTER TABLE airbnb.listings
RENAME COLUMN price TO price_usd;
