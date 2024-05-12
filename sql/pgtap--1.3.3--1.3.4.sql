-- trigger_events_are ( table, trigger, events[], description )
CREATE OR REPLACE FUNCTION trigger_events_are(
    NAME,
    NAME,
    NAME[],
    text
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
        WHERE event_object_table = $1
        AND trigger_name = $2
    ) THEN
        RETURN ok(false, 'Trigger ' || $2 || ' does not exist on table ' || $1);
    END IF;

    -- Fetch trigger events based on provided parameters
    found_events := _get_trigger_events($1, $2);

    -- RAISE NOTICE 'test event: %', ARRAY_TO_STRING(found_events, ', ');

    -- Compare expected events with found events to identify missing and extra events
    missing_events := ARRAY(
        SELECT unnest($3)
        EXCEPT
        SELECT unnest(found_events)
    );

    extra_events := ARRAY(
        SELECT unnest(found_events)
        EXCEPT
        SELECT unnest($3)
    );

    RETURN _are(
        'events',
        extra_events,
        missing_events,
        $4
    );
END;
$$ LANGUAGE plpgsql;

-- trigger_events_are ( table, trigger, events[] ) -- default description - check if this is covered above
-- trigger_events_are ( schema, table, trigger, events[], description ) -- TODO! Add with schema

-- Helper to get trigger events
CREATE OR REPLACE FUNCTION _get_trigger_events(
    p_table_name text,
    p_trigger_name text,
    p_expected_timing text DEFAULT NULL
)
RETURNS TEXT[] AS $$
DECLARE
    trigger_timing_filter text;
BEGIN
    IF p_expected_timing IS NOT NULL THEN
        trigger_timing_filter := ' AND trigger_timing = ' || quote_literal(p_expected_timing);
    ELSE
        trigger_timing_filter := '';
    END IF;

    RETURN ARRAY(
        SELECT upper(event_manipulation)
        FROM information_schema.triggers
        WHERE event_object_table = p_table_name
        AND trigger_name = p_trigger_name
        || trigger_timing_filter
    );
END;
$$ LANGUAGE plpgsql;