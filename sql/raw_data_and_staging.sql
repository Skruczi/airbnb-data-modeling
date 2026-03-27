CREATE SCHEMA airbnb;

-- raw table
CREATE TABLE airbnb.raw_listings (
    id TEXT,
    listing_url TEXT,
    scrape_id TEXT,
    last_scraped DATE,
    source TEXT,
    name TEXT,
    description TEXT,
    neighborhood_overview TEXT,
    picture_url TEXT,
    host_id TEXT,
    host_url TEXT,
    host_name TEXT,
    host_since DATE,
    host_location TEXT,
    host_about TEXT,
    host_response_time TEXT,
    host_response_rate TEXT,
    host_acceptance_rate TEXT,
    host_is_superhost TEXT,
    host_thumbnail_url TEXT,
    host_picture_url TEXT,
    host_neighbourhood TEXT,
    host_listings_count TEXT,
    host_total_listings_count TEXT,
    host_verifications TEXT,
    host_has_profile_pic TEXT,
    host_identity_verified TEXT,
    neighbourhood TEXT,
    neighbourhood_cleansed TEXT,
    neighbourhood_group_cleansed TEXT,
    latitude TEXT,
    longitude TEXT,
    property_type TEXT,
    room_type TEXT,
    accommodates TEXT,
    bathrooms TEXT,
    bathrooms_text TEXT,
    bedrooms TEXT,
    beds TEXT,
    amenities TEXT,
    price TEXT,
    minimum_nights TEXT,
    maximum_nights TEXT,
    minimum_minimum_nights TEXT,
    maximum_minimum_nights TEXT,
    minimum_maximum_nights TEXT,
    maximum_maximum_nights TEXT,
    minimum_nights_avg_ntm TEXT,
    maximum_nights_avg_ntm TEXT,
    calendar_updated TEXT,
    has_availability TEXT,
    availability_30 TEXT,
    availability_60 TEXT,
    availability_90 TEXT,
    availability_365 TEXT,
    calendar_last_scraped DATE,
    number_of_reviews TEXT,
    number_of_reviews_ltm TEXT,
    number_of_reviews_l30d TEXT,
    availability_eoy TEXT,
    number_of_reviews_ly TEXT,
    estimated_occupancy_l365d TEXT,
    estimated_revenue_l365d TEXT,
    first_review DATE,
    last_review DATE,
    review_scores_rating TEXT,
    review_scores_accuracy TEXT,
    review_scores_cleanliness TEXT,
    review_scores_checkin TEXT,
    review_scores_communication TEXT,
    review_scores_location TEXT,
    review_scores_value TEXT,
    license TEXT,
    instant_bookable TEXT,
    calculated_host_listings_count TEXT,
    calculated_host_listings_count_entire_homes TEXT,
    calculated_host_listings_count_private_rooms TEXT,
    calculated_host_listings_count_shared_rooms TEXT,
    reviews_per_month TEXT
);


-- Staging
CREATE TABLE airbnb.stg_listings AS
SELECT
    -- IDENTIFICATORS
    id::BIGINT AS listing_id,
    listing_url,
    scrape_id::BIGINT,
    last_scraped::DATE,
    source,

    -- LISTING INFO
    name,
    description,
    neighborhood_overview,
    picture_url,

    -- HOST
    host_id::BIGINT,
    host_url,
    host_name,
    host_since::DATE,
    host_location,
    host_about,

    host_response_time,

    CASE 
        WHEN host_response_rate IN ('N/A', '', 'null') THEN NULL
        ELSE REPLACE(host_response_rate, '%', '')::NUMERIC
    END AS host_response_rate,

    CASE 
        WHEN host_acceptance_rate IN ('N/A', '', 'null') THEN NULL
        ELSE REPLACE(host_acceptance_rate, '%', '')::NUMERIC
    END AS host_acceptance_rate,

    (host_is_superhost = 't') AS host_is_superhost,

    host_thumbnail_url,
    host_picture_url,
    host_neighbourhood,

    host_listings_count::INT,
    host_total_listings_count::INT,

    host_verifications,

    (host_has_profile_pic = 't') AS host_has_profile_pic,
    (host_identity_verified = 't') AS host_identity_verified,

    -- LOCATION
    neighbourhood,
    neighbourhood_cleansed,
    neighbourhood_group_cleansed,

    latitude::DECIMAL(9,6),
    longitude::DECIMAL(9,6),

    -- PROPERTY
    property_type,
    room_type,

    accommodates::INT,

    CASE 
        WHEN bathrooms IN ('N/A', '', 'null') THEN NULL
        ELSE bathrooms::NUMERIC(3,1)
    END AS bathrooms,

    bathrooms_text,

    bedrooms::INT,
    beds::INT,

    -- JSON
    amenities::JSON,

    -- PRICE
    CASE 
        WHEN price IN ('N/A', '', 'null') THEN NULL
        ELSE REPLACE(REPLACE(price, '$', ''), ',', '')::NUMERIC(10,2)
    END AS price,

    -- RULES
    minimum_nights::INT,
    maximum_nights::INT,

    minimum_minimum_nights::INT,
    maximum_minimum_nights::INT,
    minimum_maximum_nights::INT,
    maximum_maximum_nights::INT,

    minimum_nights_avg_ntm::NUMERIC,
    maximum_nights_avg_ntm::NUMERIC,

    -- AVAILABILITY
    (has_availability = 't') AS has_availability,

    availability_30::INT,
    availability_60::INT,
    availability_90::INT,
    availability_365::INT,

    availability_eoy::INT,

    calendar_last_scraped::DATE,

    -- REVIEWS
    number_of_reviews::INT,
    number_of_reviews_ltm::INT,
    number_of_reviews_l30d::INT,
    number_of_reviews_ly::INT,

    first_review::DATE,
    last_review::DATE,

    review_scores_rating::NUMERIC(3,2),
    review_scores_accuracy::NUMERIC(3,2),
    review_scores_cleanliness::NUMERIC(3,2),
    review_scores_checkin::NUMERIC(3,2),
    review_scores_communication::NUMERIC(3,2),
    review_scores_location::NUMERIC(3,2),
    review_scores_value::NUMERIC(3,2),

    reviews_per_month::NUMERIC(4,2),

    -- BUSINESS
    estimated_occupancy_l365d::INT,
    CASE
        WHEN estimated_revenue_l365d IS NULL THEN NULL
        ELSE REPLACE(estimated_revenue_l365d::TEXT, ',', '')::NUMERIC(12,2)
    END AS estimated_revenue_l365d,

    -- META
    license,

    (instant_bookable = 't') AS instant_bookable,

    calculated_host_listings_count::INT,
    calculated_host_listings_count_entire_homes::INT,
    calculated_host_listings_count_private_rooms::INT,
    calculated_host_listings_count_shared_rooms::INT

FROM airbnb.raw_listings;

-- staging fix -> changing 'N/A' & other undefined values to NULL
UPDATE airbnb.stg_listings
SET host_response_time = NULL
WHERE host_response_time IN ('N/A', '', 'null');
