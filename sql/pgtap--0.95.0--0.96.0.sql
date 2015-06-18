CREATE OR REPLACE FUNCTION pgtap_version()
RETURNS NUMERIC AS 'SELECT 0.96;'
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION findfuncs( NAME, TEXT, TEXT )
RETURNS TEXT[] AS $$
    SELECT ARRAY(
        SELECT DISTINCT quote_ident(n.nspname) || '.' || quote_ident(p.proname) AS pname
          FROM pg_catalog.pg_proc p
          JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = $1
           AND p.proname ~ $2
           AND ($3 IS NULL OR p.proname !~ $3)
         ORDER BY pname
    );
$$ LANGUAGE sql;
CREATE OR REPLACE FUNCTION findfuncs( NAME, TEXT )
RETURNS TEXT[] AS $$
    SELECT findfuncs( $1, $2, NULL )
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION findfuncs( TEXT, TEXT )
RETURNS TEXT[] AS $$
    SELECT ARRAY(
        SELECT DISTINCT quote_ident(n.nspname) || '.' || quote_ident(p.proname) AS pname
          FROM pg_catalog.pg_proc p
          JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
         WHERE pg_catalog.pg_function_is_visible(p.oid)
           AND p.proname ~ $1
           AND ($2 IS NULL OR p.proname !~ $2)
         ORDER BY pname
    );
$$ LANGUAGE sql;
CREATE OR REPLACE FUNCTION findfuncs( TEXT )
RETURNS TEXT[] AS $$
    SELECT findfuncs( $1, NULL )
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION runtests( NAME, TEXT )
RETURNS SETOF TEXT AS $$
    SELECT * FROM _runner(
        findfuncs( $1, '^startup' ),
        findfuncs( $1, '^shutdown' ),
        findfuncs( $1, '^setup' ),
        findfuncs( $1, '^teardown' ),
        findfuncs( $1, $2, '^(startup|shutdown|setup|teardown)' )
    );
$$ LANGUAGE sql;

-- runtests( match )
CREATE OR REPLACE FUNCTION runtests( TEXT )
RETURNS SETOF TEXT AS $$
    SELECT * FROM _runner(
        findfuncs( '^startup' ),
        findfuncs( '^shutdown' ),
        findfuncs( '^setup' ),
        findfuncs( '^teardown' ),
        findfuncs( $1, '^(startup|shutdown|setup|teardown)' )
    );
$$ LANGUAGE sql;
