\unset ECHO
\i test/setup.sql

SELECT plan(97);
--SELECT * FROM no_plan();

-- This will be rolled back. :-)
SET client_min_messages = warning;
CREATE TABLE public.users(
    nick  text NOT NULL PRIMARY KEY,
    pass  text NOT NULL
);
CREATE FUNCTION public.hash_pass() RETURNS TRIGGER AS '
BEGIN
    NEW.pass := MD5( NEW.pass );
    RETURN NEW;
END;
' LANGUAGE plpgsql;

CREATE TRIGGER set_users_pass
BEFORE INSERT ON public.users
FOR EACH ROW EXECUTE PROCEDURE hash_pass();

CREATE TRIGGER upd_users_pass
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE PROCEDURE hash_pass();
RESET client_min_messages;

-- trigger_events_are seed
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name TEXT
);

-- Create a trigger on the test table
CREATE OR REPLACE FUNCTION test_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    -- Trigger function logic here
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER test_trigger
AFTER INSERT OR UPDATE ON test_table
FOR EACH ROW
EXECUTE FUNCTION test_trigger_function();

/****************************************************************************/
-- Test has_trigger() and hasnt_trigger().

SELECT * FROM check_test(
    has_trigger( 'public', 'users', 'set_users_pass', 'whatever' ),
    true,
    'has_trigger(schema, table, trigger, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    has_trigger( 'public', 'users', 'set_users_pass'::name ),
    true,
    'has_trigger(schema, table, trigger)',
    'Table public.users should have trigger set_users_pass',
    ''
);

SELECT * FROM check_test(
    has_trigger( 'users', 'set_users_pass', 'whatever' ),
    true,
    'has_trigger(table, trigger, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    has_trigger( 'users', 'set_users_pass' ),
    true,
    'has_trigger(table, trigger)',
    'Table users should have trigger set_users_pass',
    ''
);

SELECT * FROM check_test(
    has_trigger( 'public', 'users', 'nosuch', 'whatever' ),
    false,
    'has_trigger(schema, table, nonexistent, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    has_trigger( 'users', 'nosuch' ),
    false,
    'has_trigger(table, nonexistent) no schema fail',
    'Table users should have trigger nosuch',
    ''
);

SELECT * FROM check_test(
    hasnt_trigger( 'public', 'users', 'set_users_pass', 'whatever' ),
    false,
    'hasnt_trigger(schema, table, trigger, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    hasnt_trigger( 'public', 'users', 'set_users_pass'::name ),
    false,
    'hasnt_trigger(schema, table, trigger)',
    'Table public.users should not have trigger set_users_pass',
    ''
);

SELECT * FROM check_test(
    hasnt_trigger( 'users', 'set_users_pass', 'whatever' ),
    false,
    'hasnt_trigger(table, trigger, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    hasnt_trigger( 'users', 'set_users_pass' ),
    false,
    'hasnt_trigger(table, trigger)',
    'Table users should not have trigger set_users_pass',
    ''
);

SELECT * FROM check_test(
    hasnt_trigger( 'public', 'users', 'nosuch', 'whatever' ),
    true,
    'hasnt_trigger(schema, table, nonexistent, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    hasnt_trigger( 'users', 'nosuch' ),
    true,
    'hasnt_trigger(table, nonexistent) no schema fail',
    'Table users should not have trigger nosuch',
    ''
);

/****************************************************************************/
-- test trigger_is()

SELECT * FROM check_test(
    trigger_is( 'public', 'users', 'set_users_pass', 'public', 'hash_pass', 'whatever' ),
    true,
    'trigger_is()',
    'whatever',
    ''
);

SELECT * FROM check_test(
    trigger_is( 'public', 'users', 'set_users_pass', 'public', 'hash_pass' ),
    true,
    'trigger_is() no desc',
    'Trigger set_users_pass should call public.hash_pass()',
    ''
);

SELECT * FROM check_test(
    trigger_is( 'users', 'set_users_pass', 'hash_pass', 'whatever' ),
    true,
    'trigger_is() no schema',
    'whatever',
    ''
);

SELECT * FROM check_test(
    trigger_is( 'users', 'set_users_pass', 'hash_pass' ),
    true,
    'trigger_is() no schema or desc',
    'Trigger set_users_pass should call hash_pass()',
    ''
);

SELECT * FROM check_test(
    trigger_is( 'public', 'users', 'set_users_pass', 'public', 'oops', 'whatever' ),
    false,
    'trigger_is() fail',
    'whatever',
    '        have: public.hash_pass
        want: public.oops'
);

SELECT * FROM check_test(
    trigger_is( 'users', 'set_users_pass', 'oops' ),
    false,
    'trigger_is() no schema fail',
    'Trigger set_users_pass should call oops()',
    '        have: hash_pass
        want: oops'
);

/****************************************************************************/
-- Test triggers_are().
SELECT * FROM check_test(
    triggers_are( 'public', 'users', ARRAY['set_users_pass', 'upd_users_pass'], 'whatever' ),
    true,
    'triggers_are(schema, table, triggers, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    triggers_are( 'public', 'users', ARRAY['set_users_pass', 'upd_users_pass'] ),
    true,
    'triggers_are(schema, table, triggers)',
    'Table public.users should have the correct triggers',
    ''
);

SELECT * FROM check_test(
    triggers_are( 'public', 'users', ARRAY['set_users_pass'] ),
    false,
    'triggers_are(schema, table, triggers) + extra',
    'Table public.users should have the correct triggers',
    '    Extra triggers:
        upd_users_pass'
);

SELECT * FROM check_test(
    triggers_are( 'public', 'users', ARRAY['set_users_pass', 'upd_users_pass', 'howdy'] ),
    false,
    'triggers_are(schema, table, triggers) + missing',
    'Table public.users should have the correct triggers',
    '    Missing triggers:
        howdy'
);

SELECT * FROM check_test(
    triggers_are( 'public', 'users', ARRAY['set_users_pass', 'howdy'] ),
    false,
    'triggers_are(schema, table, triggers) + extra & missing',
    'Table public.users should have the correct triggers',
    '    Extra triggers:
        upd_users_pass
    Missing triggers:
        howdy'
);

SELECT * FROM check_test(
    triggers_are( 'users', ARRAY['set_users_pass', 'upd_users_pass'], 'whatever' ),
    true,
    'triggers_are(table, triggers, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    triggers_are( 'users', ARRAY['set_users_pass', 'upd_users_pass'] ),
    true,
    'triggers_are(table, triggers)',
    'Table users should have the correct triggers',
    ''
);

SELECT * FROM check_test(
    triggers_are( 'users', ARRAY['set_users_pass'] ),
    false,
    'triggers_are(table, triggers) + extra',
    'Table users should have the correct triggers',
    '    Extra triggers:
        upd_users_pass'
);

SELECT * FROM check_test(
    triggers_are( 'users', ARRAY['set_users_pass', 'upd_users_pass', 'howdy'] ),
    false,
    'triggers_are(table, triggers) + missing',
    'Table users should have the correct triggers',
    '    Missing triggers:
        howdy'
);

SELECT * FROM check_test(
    triggers_are( 'users', ARRAY['set_users_pass', 'howdy'] ),
    false,
    'triggers_are(table, triggers) + extra & missing',
    'Table users should have the correct triggers',
    '    Extra triggers:
        upd_users_pass
    Missing triggers:
        howdy'
);

/****************************************************************************/
-- Test triggers_events_are().
-- Test Case 1: No missing or extra events (Both INSERT and UPDATE are expected).
SELECT * FROM check_test(
    trigger_events_are('test_table', 'test_trigger', ARRAY['INSERT', 'UPDATE'], 'should have no missing or extra events'),
    true,
    'trigger_events_are(table, trigger, events, desc)'
);

-- Test Case 2: Missing event (Only INSERT is expected).
SELECT * FROM check_test(
    trigger_events_are('test_table', 'test_trigger', ARRAY['INSERT'], 'should fail with extra event UPDATE'),
    false,
    'trigger_events_are(table, trigger, events, desc) + extra',
    'should fail with extra event UPDATE',
    E'    Extra events:\n        "UPDATE"'
);

-- Test Case 3: Extra event (Only UPDATE is expected). --> TODO! Change so only getting missing Event
SELECT * FROM check_test(
    trigger_events_are('test_table', 'test_trigger', ARRAY['UPDATE'], 'should fail with extra event INSERT'),
    false,
    'trigger_events_are(table, trigger, events, desc)',
    'should fail with extra event INSERT',
    E'    Extra events:\n        "INSERT"'
);

-- Test Case 4: Both missing and extra events (Only DELETE is expected).
SELECT * FROM check_test(
    trigger_events_are('test_table', 'test_trigger', ARRAY['DELETE'], 'should fail with both missing and extra events'), 
    false,
    'trigger_events_are(table, trigger, events, desc) + extra & missing',
    'should fail with both missing and extra events',
    E'    Extra events:\n        "INSERT"\n        "UPDATE"\n    Missing events:\n        "DELETE"'
);

-- Test Case 5: Trigger does not exist.
SELECT * FROM check_test(
    trigger_events_are('test_table', 'non_existent_trigger', ARRAY['INSERT'], 'should fail - trigger does not exist'),
    false,
    'trigger_events_are(table, non_existent_trigger, events, desc)'
);

-- Test Case 6: Table does not exist.
SELECT * FROM check_test(
    trigger_events_are('non_existent_table', 'test_trigger', ARRAY['INSERT'], 'should fail - table does not exist'),
    false,
    'trigger_events_are(non_existent_table, trigger, events, desc)'
);

-- Test Case 7: Empty events.
SELECT * FROM check_test(
    trigger_events_are('test_table', 'test_trigger', ARRAY[]::TEXT[], 'should fail with both missing and extra events'),
    false,
    'trigger_events_are(table, trigger, ARRAY[], desc)'
);


/****************************************************************************/
-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
