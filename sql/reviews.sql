CREATE TABLE airbnb.reviews (
    listing_id BIGINT PRIMARY KEY REFERENCES airbnb.listings(listing_id),

    number_of_reviews INT,
    number_of_reviews_ltm INT,
    number_of_reviews_l30d INT,
    number_of_reviews_ly INT,

    first_review DATE,
    last_review DATE,

    review_scores_rating NUMERIC(3,2),
    review_scores_accuracy NUMERIC(3,2),
    review_scores_cleanliness NUMERIC(3,2),
    review_scores_checkin NUMERIC(3,2),
    review_scores_communication NUMERIC(3,2),
    review_scores_location NUMERIC(3,2),
    review_scores_value NUMERIC(3,2),

    reviews_per_month NUMERIC(4,2)
);

INSERT INTO airbnb.reviews
SELECT
    listing_id,
    number_of_reviews,
    number_of_reviews_ltm,
    number_of_reviews_l30d,
    number_of_reviews_ly,
    first_review,
    last_review,
    review_scores_rating,
    review_scores_accuracy,
    review_scores_cleanliness,
    review_scores_checkin,
    review_scores_communication,
    review_scores_location,
    review_scores_value,
    reviews_per_month
FROM airbnb.stg_listings;

ALTER TABLE airbnb.reviews
ALTER COLUMN listing_id SET NOT NULL;


-- add boolean column for analytics about reviews

ALTER TABLE airbnb.reviews
ADD COLUMN has_reviews BOOLEAN;

UPDATE airbnb.reviews
SET has_reviews =
    CASE
        WHEN number_of_reviews > 0 THEN TRUE
        ELSE FALSE
    END;


-- analytics layer (compute on demand)
SELECT
    listing_id,
    number_of_reviews,
    number_of_reviews_ltm,
    number_of_reviews_l30d,

    -- monthly activity
    number_of_reviews_ltm / 12.0 AS reviews_per_month_ltm,

    -- momentum
    number_of_reviews_l30d / NULLIF(number_of_reviews_ltm / 12.0, 0) AS reviews_momentum,

    -- avg score
    (
        review_scores_accuracy +
        review_scores_cleanliness +
        review_scores_checkin +
        review_scores_communication +
        review_scores_location +
        review_scores_value
    ) / 6.0 AS avg_review_score,

    -- weighted rating
    (
        review_scores_rating * number_of_reviews
        + 4.5 * 50
    ) / NULLIF(number_of_reviews + 50, 0) AS weighted_rating,

    -- growth
    (number_of_reviews_ltm - number_of_reviews_ly) AS reviews_growth

FROM airbnb.reviews;
