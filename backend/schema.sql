-- =============================================================
-- MerchQuest PostgreSQL Schema
-- =============================================================
-- Balance is computed dynamically:
--   earned  = SUM(coins.value) WHERE user_coins.user_id = ?
--   spent   = SUM(orders.order_total) WHERE orders.user_id = ?
--   balance = earned - spent
-- =============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- USERS
-- Guest sessions identified by a UUID stored in a cookie.
-- =============================================================
CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- DELEGATES
-- Event badge validation. One delegate record per user (max).
-- delegate_id is the badge/ticket identifier from the event system.
-- =============================================================
CREATE TABLE delegates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    delegate_id TEXT NOT NULL UNIQUE,
    validated   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_delegates_user_id ON delegates(user_id);

-- =============================================================
-- COINS
-- Collectible virtual coins placed at physical event locations.
-- id is a sequential integer matching the in-memory list index.
-- =============================================================
CREATE TABLE coins (
    id          SERIAL PRIMARY KEY,
    locationref TEXT    NOT NULL,
    value       INTEGER NOT NULL CHECK (value > 0),
    glb_ref     TEXT    NOT NULL
);

-- =============================================================
-- USER_COINS
-- Records which coins each user has collected.
-- A user can collect each coin at most once (composite PK).
-- =============================================================
CREATE TABLE user_coins (
    user_id      UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coin_id      INTEGER NOT NULL REFERENCES coins(id) ON DELETE CASCADE,
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, coin_id)
);

CREATE INDEX idx_user_coins_user_id ON user_coins(user_id);

-- =============================================================
-- VENDORS
-- Merchandise booths at the event.
-- =============================================================
CREATE TABLE vendors (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- MERCH_STOCK
-- Global merchandise catalogue.
-- id is a string identifier (slug or UUID string).
-- price is in coins.
-- =============================================================
CREATE TABLE merch_stock (
    id              TEXT    PRIMARY KEY,
    price           INTEGER NOT NULL CHECK (price >= 0),
    stock_remaining INTEGER NOT NULL DEFAULT 0 CHECK (stock_remaining >= 0)
);

-- =============================================================
-- VENDOR_STOCK
-- Per-vendor item availability.
-- Maps vendors to the items they carry and their current quantity.
-- =============================================================
CREATE TABLE vendor_stock (
    vendor_id     UUID    NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    stock_item_id TEXT    NOT NULL REFERENCES merch_stock(id) ON DELETE CASCADE,
    quantity      INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    PRIMARY KEY (vendor_id, stock_item_id)
);

CREATE INDEX idx_vendor_stock_vendor_id ON vendor_stock(vendor_id);

-- =============================================================
-- ORDERS
-- Checkout transactions. items is a JSONB map of
-- {stock_item_id: quantity} matching CheckoutRequest.items.
-- order_total is the total coins deducted from the user.
-- =============================================================
CREATE TABLE orders (
    id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID    NOT NULL REFERENCES users(id),
    vendor_id   UUID    NOT NULL REFERENCES vendors(id),
    items       JSONB   NOT NULL,
    order_total INTEGER NOT NULL CHECK (order_total >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user_id   ON orders(user_id);
CREATE INDEX idx_orders_vendor_id ON orders(vendor_id);

-- =============================================================
-- COMPUTED BALANCE VIEW
-- Convenience view: earned coins minus spent coins per user.
-- =============================================================
CREATE VIEW user_balances AS
SELECT
    u.id AS user_id,
    COALESCE(earned.total, 0) - COALESCE(spent.total, 0) AS balance
FROM users u
LEFT JOIN (
    SELECT uc.user_id, SUM(c.value) AS total
    FROM user_coins uc
    JOIN coins c ON c.id = uc.coin_id
    GROUP BY uc.user_id
) earned ON earned.user_id = u.id
LEFT JOIN (
    SELECT user_id, SUM(order_total) AS total
    FROM orders
    GROUP BY user_id
) spent ON spent.user_id = u.id;