-- trigger_events_are( schema, table, trigger, events[], description )
CREATE OR REPLACE FUNCTION trigger_events_are(
    NAME,
    NAME,
    NAME,
    NAME[],
    TEXT
)
RETURNS TEXT AS $$
DECLARE
    found_events TEXT[];
    extra_events TEXT[];
    missing_events TEXT[];
    result TEXT;
BEGIN
    -- Check if the trigger exists
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.triggers
        WHERE (
            ( $1 IS NULL OR event_object_schema = $1 )  -- Optional schema check
            AND event_object_table = $2
            AND trigger_name = $3
        )
    ) THEN
        RETURN 'Trigger ' || $3 || ' does not exist on table ' || coalesce($1 || '.', '') || $2;
    END IF;

    -- Fetch trigger events based on provided parameters
    found_events := _get_trigger_events($1, $2, $3);

    -- RAISE NOTICE 'test event: %', ARRAY_TO_STRING(found_events, ', ');

    -- Compare expected events with found events to identify missing and extra events
    missing_events := ARRAY(
        SELECT unnest($4)
        EXCEPT
        SELECT unnest(found_events)
    );

    extra_events := ARRAY(
        SELECT unnest(found_events)
        EXCEPT
        SELECT unnest($4)
    );

    RETURN _are(
        'events',
        extra_events,
        missing_events,
        $5
    );
END;
$$ LANGUAGE plpgsql;


-- trigger_events_are ( table, trigger, events[] ) -- default description - check if this is covered above

-- trigger_events_are ( table, trigger, events[], description )
-- CREATE OR REPLACE FUNCTION trigger_events_are(
--     NAME,
--     NAME,
--     NAME[],
--     TEXT
-- )
-- RETURNS TEXT AS $$
-- DECLARE
--     found_events TEXT[];
--     extra_events TEXT[];
--     missing_events TEXT[];
--     result TEXT;
-- BEGIN
--     -- Check if the trigger exists
--     IF NOT EXISTS (
--         SELECT 1
--         FROM information_schema.triggers
--         WHERE event_object_schema NOT IN ('pg_catalog', 'information_schema')
--         AND event_object_table = $1
--         AND trigger_name = $2
--     ) THEN
--         RETURN 'Trigger ' || $2 || ' does not exist on table ' || $2;
--     END IF;

--     -- Fetch trigger events based on provided parameters
--     found_events := _get_trigger_events($1, $2);

--     -- RAISE NOTICE 'test event: %', ARRAY_TO_STRING(found_events, ', ');

--     -- Compare expected events with found events to identify missing and extra events
--     missing_events := ARRAY(
--         SELECT unnest($4)
--         EXCEPT
--         SELECT unnest(found_events)
--     );

--     extra_events := ARRAY(
--         SELECT unnest(found_events)
--         EXCEPT
--         SELECT unnest($4)
--     );

--     RETURN _are(
--         'events',
--         extra_events,
--         missing_events,
--         $5
--     );
-- END;
-- $$ LANGUAGE plpgsql;

-- Helper to get trigger events
CREATE OR REPLACE FUNCTION _get_trigger_events(
    p_table_name TEXT,
    p_trigger_name TEXT,
    p_schema_name TEXT DEFAULT NULL,
    p_expected_timing TEXT DEFAULT NULL
)
RETURNS TEXT[] AS $$
DECLARE
    trigger_timing_filter TEXT;
BEGIN
    IF p_expected_timing IS NOT NULL THEN
        trigger_timing_filter := ' AND trigger_timing = ' || quote_literal(p_expected_timing);
    ELSE
        trigger_timing_filter := '';
    END IF;

    RETURN ARRAY(
        SELECT upper(event_manipulation)
        FROM information_schema.triggers
        WHERE (
            (p_schema_name IS NULL OR event_object_schema = p_schema_name)
            AND event_object_table = p_table_name
            AND trigger_name = p_trigger_name
        )
        || trigger_timing_filter
    );
END;
$$ LANGUAGE plpgsql;