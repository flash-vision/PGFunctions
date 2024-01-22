/*
  Generate_uuid7
  Hunter/FlashParking/2024
  UUID version 7 aims to provide a timestamp-based UUID with a more precise timestamp and a reduced randomness section. 
  The general structure of a UUID v7 (as per the current draft specification) includes a Unix timestamp with millisecond precision and a custom randomness section.

  Here's a basic example of how you might implement a function in PL/pgSQL to generate a UUID version 7-like value. 
  Please note that this is a simplified version and may not fully comply with all aspects of the UUID v7 specification:

*/
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION generate_uuid_v7()
RETURNS uuid AS $$
DECLARE
    unix_time_ms BIGINT;
    node_id BYTEA;
    clock_seq INTEGER;
    version_and_timestamp BIGINT;
    uuid_val BYTEA;
    hex_string TEXT;
BEGIN
    -- Get Unix timestamp in milliseconds
    unix_time_ms := EXTRACT(EPOCH FROM clock_timestamp()) * 1000;

    -- Generate random node ID (6 bytes) and clock sequence (2 bytes)
    node_id := gen_random_bytes(6);
    clock_seq := (RANDOM() * 65535)::INTEGER;

    -- Construct the 60-bit timestamp value and set the version (0111 for v7)
    -- Shifting the version bits and timestamp into the correct position
    version_and_timestamp := ((unix_time_ms << 4) | (7 << 60));

    -- Convert to bytea
    uuid_val := SET_BYTE(SET_BYTE(SET_BYTE(SET_BYTE(SET_BYTE(SET_BYTE(
                 int8send(version_and_timestamp), 0, GET_BYTE(int8send(clock_seq), 1)), 1, GET_BYTE(int8send(clock_seq), 0)),
                 2, GET_BYTE(node_id, 0)), 3, GET_BYTE(node_id, 1)), 4, GET_BYTE(node_id, 2)), 5, GET_BYTE(node_id, 3));

    -- Append the remaining node ID bytes
    uuid_val := uuid_val || SUBSTRING(node_id FROM 4 FOR 3);

    -- Convert to hex string
    hex_string := encode(uuid_val, 'hex');

    -- Format as UUID
    hex_string := left(hex_string, 8) || '-' || 
                  substring(hex_string from 9 for 4) || '-' || 
                  substring(hex_string from 13 for 4) || '-' || 
                  substring(hex_string from 17 for 4) || '-' || 
                  right(hex_string, 12);

    -- Convert to UUID
    RETURN hex_string::uuid;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Example usage
SELECT generate_uuid_v7();

