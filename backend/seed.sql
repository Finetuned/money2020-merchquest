-- =============================================================
-- MerchQuest Seed Data
-- =============================================================
-- Run AFTER schema.sql
--
-- Coin IDs are 1-based (PostgreSQL SERIAL default).
-- QR codes MUST encode coin_id values starting from 1.
-- The qr_lookup.js in www/src/routes/Scanner/ maps QR URLs
-- to coin_id values and MUST use 1-based IDs.
-- =============================================================

-- Coins
INSERT INTO coins (locationref, value, glb_ref) VALUES
    ('Z', 10, 'coin.glb'),
    ('A', 10, 'coin.glb'),
    ('B', 10, 'coin.glb'),
    ('C', 10, 'coin.glb'),
    ('D', 10, 'coin.glb'),
    ('E', 10, 'coin.glb');
-- IDs assigned: 1, 2, 3, 4, 5, 6

-- Merch stock
INSERT INTO merch_stock (id, name, price, stock_remaining) VALUES
    ('t-shirt', 'T-Shirt', 1, 100),
    ('hat', 'Hat', 1, 100),
    ('hoody', 'Hoody', 1, 100),
    ('socks', 'Socks', 1, 100),
    ('vest', 'Vest', 1, 100)
ON CONFLICT (id) DO NOTHING;
