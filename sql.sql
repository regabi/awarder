SELECT segments.*
FROM segments
LEFT OUTER JOIN itineraries_segments ON itineraries_segments.segment_id = segments.id
LEFT OUTER JOIN itineraries ON itineraries.id = itineraries_segments.itinerary_id
WHERE itineraries.business_miles IS NOT NULL
  AND segments.local_date IN ('2015-04-28', '2015-04-29')
  AND travel_time > 300
GROUP BY segments.id