-- =============================================================
-- MerchQuest Seed Data
-- =============================================================
-- Run AFTER schema.sql
-- Seeds the 6 initial coins from frontend/backend/main.py
-- SERIAL ids will be assigned 1-6 (not 0-5 as in the Python list)
-- The API uses coin_id as the SERIAL integer.
-- =============================================================

-- Coins (matching the in-memory list in main.py)
-- Note: SERIAL starts at 1 in PostgreSQL.
-- The Python in-memory list used 0-based index.
-- If the existing API sends coin_id=0, adjust SERIAL to start at 0:
--   ALTER SEQUENCE coins_id_seq RESTART WITH 0;
-- Otherwise keep default (starts at 1) and update QR codes accordingly.

INSERT INTO coins (locationref, value, glb_ref) VALUES
    ('Z', 10, 'coin.glb'),
    ('A', 10, 'coin.glb'),
    ('B', 10, 'coin.glb'),
    ('C', 10, 'coin.glb'),
    ('D', 10, 'coin.glb'),
    ('E', 10, 'coin.glb');

-- =============================================================
-- NOTE: If QR codes encode coin_id starting from 0,
-- run the following to make SERIAL start at 0:
--
--   ALTER SEQUENCE coins_id_seq RESTART WITH 0;
--   SELECT setval('coins_id_seq', 0, false);
--
-- Then re-run the INSERT above.
-- =============================================================