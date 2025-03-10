-- Create players table if it doesn't exist
CREATE TABLE IF NOT EXISTS players (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Insert test data only if the table is empty
INSERT INTO players (name)
SELECT name
FROM (VALUES
    ('Mike Trout'),
    ('Shohei Ohtani'),
    ('Juan Soto'),
    ('Andrew McCutcheon'),
    ('Vladimir Guerrero Jr.')
) AS test_data(name)
WHERE NOT EXISTS (SELECT 1 FROM players); 