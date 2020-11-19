SELECT le.default_operating_country "Country code", 
    a.incomplete_Driver_Assignment "Incomplete Driver Assignment", 
    b.incomplete_Pickup "Incomplete Pickup", 
    c.incomplete_Dropoff "Incomplete Dropoff", 
    d.incomplete_POD "Incomplete POD"
FROM  mea.legal_entity_2 le 
LEFT JOIN (
    SELECT
        count(*) incomplete_Driver_Assignment, le.default_operating_country country_code
    FROM 
        mea.shipment_deal_2 sd
        JOIN mea.shipment_offer_2 so ON sd.offer = so.id
        JOIN mea.shipment_request_2 sr ON so.request = sr.id 
        JOIN mea.shipment_location_2 pickup on sr.pickup = pickup.id
        JOIN mea.legal_entity_2 le on le.tenant = sd.tenant_id
        LEFT JOIN mea.deal_event_2 de
            on sd.id = de.deal_id and de.type = "fulfillment_status" and de.id !=400573
            and de.payload::json->>'to' = 'WAITING_FOR_DRIVER_ASSIGNMENT'
   WHERE
        ((de.date::date) > 
        (CASE
           WHEN (pickup.from_date::date = pickup.until_date::date) THEN pickup.from_date::date
           ELSE pickup.until_date::date
       END))
      and sd.created_at::date Between '2020-09-01' AND '2020-09-30'
    group by le.default_operating_country
)  a ON  a.country_code = le.default_operating_country
LEFT JOIN (
    SELECT
        count(*) incomplete_Pickup, le.default_operating_country country_code
    FROM 
        mea.shipment_deal_2 sd
        JOIN mea.shipment_offer_2 so ON sd.offer = so.id
        JOIN mea.shipment_request_2 sr ON so.request = sr.id
        JOIN mea.legal_entity_2 le on le.tenant = sd.tenant_id
        JOIN mea.shipment_location_2 pickup on sr.pickup = pickup.id
        LEFT JOIN mea.deal_event_2 de
            on sd.id = de.deal_id and de.type = "fulfillment_status" and de.id !=400573
            and de.payload::json->>'to' = 'COLLECTED'
    WHERE
        ((de.payload::json->'annex'->'customDate')::text::date > 
        (CASE
           WHEN (pickup.from_date::date = pickup.until_date::date) THEN pickup.from_date::date
           ELSE pickup.until_date::date
       END))
        and Date(sd.created_at) Between '2020-09-01' AND '2020-09-30'
    group by le.default_operating_country
) b ON b.country_code = le.default_operating_country
LEFT JOIN (
    SELECT
         count(*) incomplete_Dropoff, le.default_operating_country country_code
    FROM 
        mea.shipment_deal_2 sd
        JOIN mea.shipment_offer_2 so ON sd.offer = so.id
        JOIN mea.shipment_request_2 sr ON so.request = sr.id
        JOIN mea.legal_entity_2 le on le.tenant = sd.tenant_id
        JOIN mea.shipment_location_2 dropOff on sr.dropoff = dropOff.id
        LEFT JOIN mea.deal_event_2 deDel
            on sd.id = deDel.deal_id and deDel.type = "fulfillment_status" and deDel.id !=400573
            and deDel.payload::json->>'to' = 'DELIVERED'
    WHERE
        ((deDel.payload::json->'annex'->'customDate')::text::date > 
        (CASE
           WHEN (dropOff.from_date::date = dropOff.until_date::date) THEN dropOff.from_date::date
           ELSE dropOff.until_date::date
       END))
        and sd.created_at::date Between '2020-09-01' AND '2020-09-30'
    group by le.default_operating_country
) c ON c.country_code = le.default_operating_country
LEFT JOIN (
    SELECT
         count(*) incomplete_POD, le.default_operating_country country_code
    FROM 
        mea.shipment_deal_2 sd
        JOIN mea.shipment_offer_2 so ON sd.offer = so.id
        JOIN mea.shipment_request_2 sr ON so.request = sr.id
        JOIN mea.legal_entity_2 le on le.tenant = sd.tenant_id
        JOIN mea.shipment_location_2 dropOff on sr.dropoff = dropOff.id
        LEFT JOIN mea.deal_event_2 dePod
          on sd.id = dePod.deal_id and dePod.type = "fulfillment_status" and dePod.id !=400573
          and dePod.payload::json->>'to' = 'POD_UPLOADED'
    WHERE
        ((dePod.date::date) > 
        (CASE
           WHEN (dropOff.from_date::date = dropOff.until_date::date) THEN dropOff.from_date::date
           ELSE dropOff.until_date::date
       END))
       and sd.created_at::date Between '2020-09-01' AND '2020-09-30'
    group by le.default_operating_country
) d ON d.country_code = le.default_operating_country