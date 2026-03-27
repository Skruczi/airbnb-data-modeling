-- create table matching reviews.csv columns exactly
CREATE TABLE airbnb.reviews_detail (
    listing_id BIGINT,
    id BIGINT PRIMARY KEY,
    date DATE,
    reviewer_id BIGINT,
    reviewer_name TEXT,
    comments TEXT
);

SELECT *
FROM airbnb.reviews_detail;

-- connect each review to its listing
ALTER TABLE airbnb.reviews_detail
ADD CONSTRAINT fk_reviews_listing
FOREIGN KEY (listing_id)
REFERENCES airbnb.listings(listing_id);

-- empty reviews (should be 0)
SELECT *
FROM airbnb.reviews_detail rd
LEFT JOIN airbnb.listings l
    ON rd.listing_id = l.listing_id
WHERE l.listing_id IS NULL;
