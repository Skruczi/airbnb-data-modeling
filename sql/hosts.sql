CREATE TABLE airbnb.hosts (
    host_id BIGINT PRIMARY KEY,

    host_name TEXT,
    host_since DATE,
    host_location TEXT,
    host_about TEXT,

    host_response_time TEXT,
    host_response_rate NUMERIC(5,2),
    host_acceptance_rate NUMERIC(5,2),

    host_is_superhost BOOLEAN,

    host_listings_count INT,
    host_total_listings_count INT,

    host_has_profile_pic BOOLEAN,
    host_identity_verified BOOLEAN
);

INSERT INTO airbnb.hosts
SELECT DISTINCT
    host_id,
    host_name,
    host_since,
    host_location,
    host_about,
    host_response_time,
    host_response_rate,
    host_acceptance_rate,
    host_is_superhost,
    host_listings_count,
    host_total_listings_count,
    host_has_profile_pic,
    host_identity_verified
FROM airbnb.stg_listings
WHERE host_id IS NOT NULL;

-- small fix -> changing 'N/A' & other undefined values to NULL
UPDATE airbnb.hosts
SET host_response_time = NULL
WHERE host_response_time IN ('N/A', '', 'null');

ALTER TABLE airbnb.hosts
ALTER COLUMN host_id SET NOT NULL;


SELECT host_response_time, COUNT(*)
FROM airbnb.hosts
GROUP BY host_response_time