SELECT listing_id, COUNT(*)
FROM airbnb.listings
GROUP BY listing_id
HAVING COUNT(*) > 1;

SELECT host_id, COUNT(*)
FROM airbnb.hosts
GROUP BY host_id
HAVING COUNT(*) > 1;

SELECT l.host_id
FROM airbnb.listings l
LEFT JOIN airbnb.hosts h ON l.host_id = h.host_id
WHERE h.host_id IS NULL;

-- conclusion: ID's are unique