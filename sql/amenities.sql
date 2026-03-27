-- checking JSON texts QUALITY
SELECT DISTINCT amenity
FROM airbnb.stg_listings,
LATERAL json_array_elements_text(amenities) AS amenity
ORDER BY amenity;


-- amenities table
CREATE TABLE airbnb.amenities (
    amenity_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- relational table
CREATE TABLE airbnb.listing_amenities (
    listing_id BIGINT NOT NULL,
    amenity_id INT NOT NULL,

    PRIMARY KEY (listing_id, amenity_id),

    FOREIGN KEY (listing_id) REFERENCES airbnb.listings(listing_id),
    FOREIGN KEY (amenity_id) REFERENCES airbnb.amenities(amenity_id)
);


-- data insertion to amenities table
INSERT INTO airbnb.amenities (name)
SELECT DISTINCT
    TRIM(
        REGEXP_REPLACE(
            LOWER(json_array_elements_text(amenities)),
            '^[^a-z0-9]+',
            ''
        )
    )
FROM airbnb.stg_listings
WHERE amenities IS NOT NULL
ON CONFLICT (name) DO NOTHING;


-- clean amenities table
CREATE TABLE airbnb.amenities_clean (
    amenity_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

INSERT INTO airbnb.amenities_clean (name)
SELECT DISTINCT
    TRIM(LOWER(regexp_split_to_table(name, ',')))
FROM airbnb.amenities
WHERE name IS NOT NULL;


-- creating relation between listing_id and amenity_id
INSERT INTO airbnb.listing_amenities (listing_id, amenity_id)
SELECT
    s.listing_id,
    ac.amenity_id
FROM airbnb.stg_listings s,
LATERAL json_array_elements_text(s.amenities) AS a_raw,
LATERAL regexp_split_to_table(a_raw, ',') AS a_part
JOIN airbnb.amenities_clean ac
    ON ac.name = TRIM(LOWER(a_part))
WHERE s.amenities IS NOT NULL
ON CONFLICT DO NOTHING;


-- checking data compliance
SELECT COUNT(*) FROM airbnb.listing_amenities;

SELECT listing_id
FROM airbnb.stg_listings
WHERE amenities IS NOT NULL
EXCEPT
SELECT DISTINCT listing_id
FROM airbnb.listing_amenities;

-- checking corrupted records (which were found)
SELECT listing_id, amenities
FROM airbnb.stg_listings
WHERE listing_id IN (1503867342263201504, 7347051);


-- amenities table check
SELECT *
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_name = 'amenities';

SELECT *
FROM information_schema.constraint_column_usage
WHERE table_name = 'amenities';

-- removing foreign key constraint
ALTER TABLE airbnb.listing_amenities
DROP CONSTRAINT listing_amenities_amenity_id_fkey;

-- adding foreign key to amenities_clean table
ALTER TABLE airbnb.listing_amenities
ADD CONSTRAINT listing_amenities_amenity_id_fkey
FOREIGN KEY (amenity_id)
REFERENCES airbnb.amenities_clean(amenity_id);

-- foreign keys check
SELECT la.amenity_id
FROM airbnb.listing_amenities la
LEFT JOIN airbnb.amenities_clean ac
    ON la.amenity_id = ac.amenity_id
WHERE ac.amenity_id IS NULL;

-- cleaning
SELECT COUNT(DISTINCT amenity_id)
FROM airbnb.listing_amenities; --2396

SELECT COUNT(*)
FROM airbnb.amenities_clean; --2397

SELECT ac.amenity_id, ac.name
FROM airbnb.amenities_clean ac
LEFT JOIN airbnb.listing_amenities la
    ON ac.amenity_id = la.amenity_id
WHERE la.amenity_id IS NULL; --amenity_id: 1225 is corrupted

DELETE FROM airbnb.amenities_clean
WHERE amenity_id = 1225;

-- dropping old amenities table
DROP TABLE airbnb.amenities;

-- renaming new amenities table
ALTER TABLE airbnb.amenities_clean
RENAME TO amenities;

-- refreshing foreign key in the new table
ALTER TABLE airbnb.listing_amenities
ADD CONSTRAINT listing_amenities_amenity_id_fkey
FOREIGN KEY (amenity_id)
REFERENCES airbnb.amenities(amenity_id);

-- dropping amenities column in listings table
ALTER TABLE airbnb.listings
DROP COLUMN amenities;


-- exploring most common words to create categories
SELECT
    word,
    COUNT(*) AS cnt
FROM (
    SELECT
        LOWER(REGEXP_SPLIT_TO_TABLE(name, '[^a-z0-9]+')) AS word
    FROM airbnb.amenities
) t
WHERE word <> ''
GROUP BY word
ORDER BY cnt DESC
LIMIT 140;

-- category column
ALTER TABLE airbnb.amenities
ADD COLUMN category_primary TEXT;

-- creating posibble categories
UPDATE airbnb.amenities
SET category_primary =
CASE

    -- WIFI
    WHEN name ILIKE '%wifi%' THEN 'wifi'

    -- TV / ENTERTAINMENT
    WHEN name ILIKE '%tv%' 
      OR name ILIKE '%netflix%' 
      OR name ILIKE '%amazon%' 
      OR name ILIKE '%hbo%' 
      OR name ILIKE '%disney%' 
      OR name ILIKE '%chromecast%'
      OR name ILIKE '%apple tv%'
    THEN 'tv_entertainment'

    -- AUDIO SYSTEM
    WHEN name ILIKE '%sound%' 
      OR name ILIKE '%bose%' 
      OR name ILIKE '%jbl%' 
      OR name ILIKE '%sonos%' 
      OR name ILIKE '%harman%' 
      OR name ILIKE '%kardon%'
      OR name ILIKE '%bluetooth%'
    THEN 'audio'

    -- KITCHEN
    WHEN name ILIKE '%oven%' 
      OR name ILIKE '%stove%' 
      OR name ILIKE '%microwave%' 
      OR name ILIKE '%coffee%' 
      OR name ILIKE '%induction%' 
      OR name ILIKE '%gas%'
      OR name ILIKE '%electric%'
    THEN 'kitchen'

    -- APPLIANCES (FRIDGE ETC)
    WHEN name ILIKE '%refrigerator%' 
      OR name ILIKE '%fridge%'
    THEN 'appliances'

    -- BATHROOM
    WHEN name ILIKE '%shampoo%' 
      OR name ILIKE '%soap%' 
      OR name ILIKE '%conditioner%' 
      OR name ILIKE '%body%'
    THEN 'bathroom'

    -- PARKING
    WHEN name ILIKE '%parking%' 
      OR name ILIKE '%garage%'
      OR name ILIKE '%spaces%'
    THEN 'parking'

    -- POOL / OUTDOOR
    WHEN name ILIKE '%pool%' 
      OR name ILIKE '%outdoor%'
      OR name ILIKE '%waterfront%'
    THEN 'outdoor'

    -- GAMING
    WHEN name ILIKE '%xbox%' 
      OR name ILIKE '%nintendo%' 
      OR name ILIKE '%game%' 
      OR name ILIKE '%console%'
    THEN 'gaming'

    -- STORAGE / FURNITURE
    WHEN name ILIKE '%storage%' 
      OR name ILIKE '%table%' 
      OR name ILIKE '%chair%'
    THEN 'furniture'

    -- FAMILY
    WHEN name ILIKE '%children%' 
      OR name ILIKE '%toys%'
      OR name ILIKE '%books%'
    THEN 'family'

    -- PETS
    WHEN name ILIKE '%pet%'
    THEN 'pets'

    ELSE NULL

END;


-- using NULL to check opportunity for new categories
SELECT
    word,
    COUNT(*) AS cnt
FROM (
    SELECT
        LOWER(REGEXP_SPLIT_TO_TABLE(name, '[^a-z0-9]+')) AS word
    FROM airbnb.amenities
    WHERE category_primary IS NULL
) t
WHERE word <> ''
GROUP BY word
ORDER BY cnt DESC;

-- creating new categories
UPDATE airbnb.amenities
SET category_primary =
CASE

    -- FITNESS
    WHEN name ILIKE '%gym%' 
      OR name ILIKE '%exercise%' 
      OR name ILIKE '%equipment%' 
      OR name ILIKE '%treadmill%' 
      OR name ILIKE '%yoga%' 
      OR name ILIKE '%weights%' 
      OR name ILIKE '%rowing%' 
      OR name ILIKE '%workout%' 
    THEN 'fitness'

    -- CLIMATE / TEMPERATURE
    WHEN name ILIKE '%heating%' 
      OR name ILIKE '%air conditioning%' 
      OR name ILIKE '%ac%' 
      OR name ILIKE '%fireplace%' 
      OR name ILIKE '%radiant%' 
      OR name ILIKE '%ductless%' 
    THEN 'climate'

    -- SAFETY
    WHEN name ILIKE '%alarm%' 
      OR name ILIKE '%smoke%' 
      OR name ILIKE '%carbon%' 
      OR name ILIKE '%extinguisher%' 
      OR name ILIKE '%lock%' 
      OR name ILIKE '%keypad%' 
    THEN 'safety'

    -- LAUNDRY / STORAGE
    WHEN name ILIKE '%washer%' 
      OR name ILIKE '%dryer%' 
      OR name ILIKE '%wardrobe%' 
      OR name ILIKE '%closet%' 
      OR name ILIKE '%hangers%' 
      OR name ILIKE '%linens%' 
      OR name ILIKE '%blankets%' 
      OR name ILIKE '%pillows%' 
    THEN 'laundry_storage'

    -- OUTDOOR EXTENSION (uzupełnienie)
    WHEN name ILIKE '%backyard%' 
      OR name ILIKE '%balcony%' 
      OR name ILIKE '%patio%' 
      OR name ILIKE '%beach%' 
      OR name ILIKE '%lake%' 
      OR name ILIKE '%garden%' 
      OR name ILIKE '%bbq%' 
      OR name ILIKE '%grill%' 
    THEN 'outdoor'

    -- FAMILY EXTENSION
    WHEN name ILIKE '%crib%' 
      OR name ILIKE '%baby%' 
      OR name ILIKE '%toys%' 
      OR name ILIKE '%babysitter%' 
    THEN 'family'

    -- BATHROOM EXTENSION
    WHEN name ILIKE '%bathtub%' 
      OR name ILIKE '%shower%' 
      OR name ILIKE '%bidet%' 
      OR name ILIKE '%tub%' 
    THEN 'bathroom'

    -- TECH / INTERNET EXTENSION
    WHEN name ILIKE '%ethernet%' 
      OR name ILIKE '%connection%' 
      OR name ILIKE '%router%' 
    THEN 'internet'

    ELSE category_primary

END
WHERE category_primary IS NULL;



-- final categories update
UPDATE airbnb.amenities
SET category_primary =
CASE

    -- WIFI
    WHEN name ILIKE '%wifi%' THEN 'wifi'

    -- TV / ENTERTAINMENT
    WHEN name ILIKE '%tv%' 
      OR name ILIKE '%netflix%' 
      OR name ILIKE '%amazon%' 
      OR name ILIKE '%hbo%' 
      OR name ILIKE '%disney%' 
      OR name ILIKE '%chromecast%'
      OR name ILIKE '%apple tv%'
      OR name ILIKE '%hulu%'
    THEN 'tv_entertainment'

    -- AUDIO
    WHEN name ILIKE '%sound%' 
      OR name ILIKE '%bose%' 
      OR name ILIKE '%jbl%' 
      OR name ILIKE '%sonos%' 
      OR name ILIKE '%harman%' 
      OR name ILIKE '%kardon%'
      OR name ILIKE '%bluetooth%'
      OR name ILIKE '%speaker%'
    THEN 'audio'

    -- KITCHEN
    WHEN name ILIKE '%oven%' 
      OR name ILIKE '%stove%' 
      OR name ILIKE '%microwave%' 
      OR name ILIKE '%coffee%' 
      OR name ILIKE '%induction%' 
      OR name ILIKE '%gas%'
      OR name ILIKE '%electric%'
      OR name ILIKE '%toaster%'
      OR name ILIKE '%blender%'
      OR name ILIKE '%kettle%'
      OR name ILIKE '%utensils%'
      OR name ILIKE '%cooking%'
    THEN 'kitchen'

    -- APPLIANCES
    WHEN name ILIKE '%refrigerator%' 
      OR name ILIKE '%fridge%'
      OR name ILIKE '%dishwasher%'
      OR name ILIKE '%freezer%'
    THEN 'appliances'

    -- BATHROOM
    WHEN name ILIKE '%shampoo%' 
      OR name ILIKE '%soap%' 
      OR name ILIKE '%conditioner%' 
      OR name ILIKE '%body%'
      OR name ILIKE '%bathtub%'
      OR name ILIKE '%shower%'
      OR name ILIKE '%bidet%'
      OR name ILIKE '%tub%'
    THEN 'bathroom'

    -- PARKING (EV też tu)
    WHEN name ILIKE '%parking%' 
      OR name ILIKE '%garage%'
      OR name ILIKE '%carport%'
      OR name ILIKE '%ev%' 
      OR name ILIKE '%charger%'
    THEN 'parking'

    -- OUTDOOR
    WHEN name ILIKE '%backyard%' 
      OR name ILIKE '%balcony%' 
      OR name ILIKE '%patio%' 
      OR name ILIKE '%bbq%' 
      OR name ILIKE '%grill%' 
      OR name ILIKE '%garden%'
    THEN 'outdoor'

    -- WATERFRONT
    WHEN name ILIKE '%ocean%' 
      OR name ILIKE '%beach%' 
      OR name ILIKE '%marina%' 
      OR name ILIKE '%waterfront%' 
      OR name ILIKE '%lake%'
      OR name ILIKE '%sea%'
    THEN 'waterfront'

    -- FITNESS
    WHEN name ILIKE '%gym%' 
      OR name ILIKE '%exercise%' 
      OR name ILIKE '%equipment%' 
      OR name ILIKE '%treadmill%' 
      OR name ILIKE '%yoga%' 
      OR name ILIKE '%weights%' 
      OR name ILIKE '%rowing%' 
      OR name ILIKE '%workout%' 
    THEN 'fitness'

    -- WELLNESS
    WHEN name ILIKE '%sauna%' 
    THEN 'wellness'

    -- CLIMATE
    WHEN name ILIKE '%heating%' 
      OR name ILIKE '%air conditioning%' 
      OR name ILIKE '%ac%' 
      OR name ILIKE '%fireplace%' 
      OR name ILIKE '%radiant%' 
      OR name ILIKE '%ductless%' 
    THEN 'climate'

    -- SAFETY
    WHEN name ILIKE '%alarm%' 
      OR name ILIKE '%smoke%' 
      OR name ILIKE '%carbon%' 
      OR name ILIKE '%extinguisher%' 
      OR name ILIKE '%lock%' 
      OR name ILIKE '%keypad%' 
      OR name ILIKE '%safe%'
    THEN 'safety'

    -- LAUNDRY / STORAGE
    WHEN name ILIKE '%washer%' 
      OR name ILIKE '%dryer%' 
      OR name ILIKE '%wardrobe%' 
      OR name ILIKE '%closet%' 
      OR name ILIKE '%hangers%' 
      OR name ILIKE '%linens%' 
      OR name ILIKE '%blankets%' 
      OR name ILIKE '%pillows%' 
    THEN 'laundry_storage'

    -- FAMILY
    WHEN name ILIKE '%crib%' 
      OR name ILIKE '%baby%' 
      OR name ILIKE '%toys%' 
      OR name ILIKE '%babysitter%' 
    THEN 'family'

    -- INTERNET / CONNECTIVITY
    WHEN name ILIKE '%ethernet%' 
      OR name ILIKE '%connection%' 
      OR name ILIKE '%router%' 
    THEN 'internet'

    -- GAMING
    WHEN name ILIKE '%xbox%' 
      OR name ILIKE '%nintendo%' 
      OR name ILIKE '%game%' 
      OR name ILIKE '%console%' 
      OR name ILIKE '%ps%'
    THEN 'gaming'

    -- FURNITURE
    WHEN name ILIKE '%table%' 
      OR name ILIKE '%chair%' 
      OR name ILIKE '%desk%' 
    THEN 'furniture'

    ELSE category_primary

END
WHERE category_primary IS NULL;


-- checking all categories
SELECT category_primary, COUNT(*)
FROM airbnb.amenities
GROUP BY category_primary;

-- bussiness decision to simplify a few categories:
UPDATE airbnb.amenities
SET category_primary =
CASE
    WHEN category_primary = 'internet' THEN 'wifi'
    WHEN category_primary IN ('pets', 'waterfront') THEN 'wellness'
    ELSE category_primary
END;



-- all names with NULL category
SELECT amenity_id, name
FROM airbnb.amenities
WHERE category_primary IS NULL
ORDER BY name;

-- polishing all categories
UPDATE airbnb.amenities
SET category_primary =
CASE

    -- KITCHEN EXTENSIONS
    WHEN name ILIKE '%baking sheet%' 
      OR name ILIKE '%bread maker%' 
      OR name ILIKE '%rice maker%' 
      OR name ILIKE '%wine glasses%' 
      OR name ILIKE '%sink%' 
      OR name ILIKE '%kitchenette%' 
    THEN 'kitchen'

    -- CLIMATE
    WHEN name ILIKE '%heated%' 
      OR name ILIKE '%wood-burning%' 
    THEN 'climate'

    -- FURNITURE / INTERIOR
    WHEN name ILIKE '%ceiling fan%' 
      OR name ILIKE '%shades%' 
      OR name ILIKE '%private entrance%' 
      OR name ILIKE '%private living room%' 
    THEN 'furniture'

    -- LAUNDRY
    WHEN name ILIKE '%iron%' 
      OR name ILIKE '%laundromat%' 
    THEN 'laundry_storage'

    -- SAFETY
    WHEN name ILIKE '%security cameras%' 
      OR name ILIKE '%window guards%' 
      OR name ILIKE '%outlet covers%' 
      OR name ILIKE '%first aid%' 
    THEN 'safety'

    -- ENTERTAINMENT
    WHEN name ILIKE '%piano%' 
      OR name ILIKE '%record player%' 
      OR name ILIKE '%movie theater%' 
      OR name ILIKE '%laser tag%' 
      OR name ILIKE '%bowling%' 
    THEN 'tv_entertainment'

    -- FITNESS
    WHEN name ILIKE '%stationary bike%' 
    THEN 'fitness'

    -- OUTDOOR / WATER ACTIVITY
    WHEN name ILIKE '%kayak%' 
      OR name ILIKE '%boat slip%' 
    THEN 'outdoor'

    -- WATER-RELATED VIEWS
    WHEN name ILIKE '%bay view%' 
      OR name ILIKE '%canal view%' 
      OR name ILIKE '%harbor view%' 
      OR name ILIKE '%river view%' 
    THEN 'wellness'

    -- OUTDOOR (views)
    WHEN name ILIKE '%city skyline view%' 
      OR name ILIKE '%courtyard view%' 
      OR name ILIKE '%desert view%' 
      OR name ILIKE '%park view%' 
      OR name ILIKE '%resort view%' 
      OR name ILIKE '%vineyard view%' 
    THEN 'outdoor'

    ELSE category_primary

END
WHERE category_primary IS NULL;



-- creating very specific categories from current tightened data
UPDATE airbnb.amenities
SET category_primary =
CASE

    -- BATHROOM (brands → hygiene)
    WHEN name ILIKE '%nivea%' 
      OR name ILIKE '%dove%' 
      OR name ILIKE '%palmolive%' 
      OR name ILIKE '%rituals%' 
      OR name ILIKE '%sanex%' 
      OR name ILIKE '%douchegel%' 
      OR name ILIKE '%handgel%' 
    THEN 'bathroom'

    -- KITCHEN / APPLIANCES (brands)
    WHEN name ILIKE '%nespresso%' 
      OR name ILIKE '%smeg%' 
      OR name ILIKE '%liebherr%' 
      OR name ILIKE '%atag%' 
    THEN 'appliances'

    -- AUDIO (brands)
    WHEN name ILIKE '%yamaha%' 
      OR name ILIKE '%denon%' 
      OR name ILIKE '%stereo%' 
    THEN 'audio'

    ELSE category_primary

END
WHERE category_primary IS NULL;

-- creating 'services' category for specific records
UPDATE airbnb.amenities
SET category_primary = 'services'
WHERE category_primary IS NULL
AND (
    name ILIKE '%housekeeping%'
    OR name ILIKE '%cleaning%'
    OR name ILIKE '%breakfast%'
    OR name ILIKE '%host%'
);


-- polishing last NULL categories by specific names
UPDATE airbnb.amenities
SET category_primary =
CASE

    -- KITCHEN
    WHEN name ILIKE '%dishes and silverware%'
      OR name ILIKE '%french press%'
      OR name = 'kitchen'
    THEN 'kitchen'

    -- TV / ENTERTAINMENT
    WHEN name ILIKE '%cd%'
      OR name ILIKE '%dvd%'
      OR name ILIKE '%cable%'
      OR name ILIKE '%spotify%'
      OR name ILIKE '%roku%'
    THEN 'tv_entertainment'

    -- OUTDOOR / ACTIVITY
    WHEN name ILIKE '%climbing wall%'
      OR name ILIKE '%hockey%'
      OR name ILIKE '%golf%'
      OR name ILIKE '%skate%'
      OR name ILIKE '%ski%'
      OR name ILIKE '%batting%'
      OR name ILIKE '%bike%'
      OR name ILIKE '%fire pit%'
      OR name ILIKE '%hammock%'
      OR name ILIKE '%loungers%'
    THEN 'outdoor'

    -- FURNITURE
    WHEN name ILIKE '%dresser%'
    THEN 'furniture'

    -- SAFETY
    WHEN name ILIKE '%mosquito%'
      OR name ILIKE '%noise decibel%'
    THEN 'safety'

    -- BATHROOM
    WHEN name ILIKE '%blendax%'
      OR name ILIKE '%hair%'
      OR name ILIKE '%hot water%'
    THEN 'bathroom'

    ELSE category_primary

END
WHERE category_primary IS NULL;
