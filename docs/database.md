# Database Schema

PostgreSQL database: `merchquest`

## Tables

### `users`

Guest sessions. Each attendee is identified by a UUID stored in an HTTP-only cookie.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | User identifier |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Session creation time |

---

### `coins`

Collectible virtual coins placed at physical event locations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Sequential coin ID (1-based) |
| `locationref` | TEXT | NOT NULL | Human-readable location label |
| `value` | INTEGER | NOT NULL, CHECK > 0 | Coin value in coins currency |
| `glb_ref` | TEXT | NOT NULL | Path/URL to the 3D GLB asset |

> **Note:** The API returns `glb_ref` as `glbRef` (camelCase alias).

---

### `user_coins`

Records which coins each user has collected. A user may collect each coin at most once.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `user_id` | UUID | NOT NULL, FK → users(id) CASCADE | Collector |
| `coin_id` | INTEGER | NOT NULL, FK → coins(id) CASCADE | Collected coin |
| `collected_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Collection timestamp |

**Primary key:** `(user_id, coin_id)`
**Index:** `idx_user_coins_user_id`

---

### `vendors`

Merchandise booths at the event.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Vendor identifier |
| `name` | TEXT | NOT NULL | Display name |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation time |

---

### `merch_stock`

Global merchandise catalogue. Defines all items available at the event.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Item slug (e.g. `hat`, `t-shirt`) |
| `price` | INTEGER | NOT NULL, CHECK >= 0 | Price in coins |
| `stock_remaining` | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 | Total units available globally |

---

### `vendor_stock`

Per-vendor item availability. Maps vendors to the items they carry and their current quantity.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `vendor_id` | UUID | NOT NULL, FK → vendors(id) CASCADE | Vendor |
| `stock_item_id` | TEXT | NOT NULL, FK → merch_stock(id) CASCADE | Item |
| `quantity` | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 | Units held by this vendor |

**Primary key:** `(vendor_id, stock_item_id)`
**Index:** `idx_vendor_stock_vendor_id`

---

### `orders`

Checkout transactions. Records every coin redemption.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Order identifier |
| `user_id` | UUID | NOT NULL, FK → users(id) | Purchasing user |
| `vendor_id` | UUID | NOT NULL, FK → vendors(id) | Vendor booth |
| `items` | JSONB | NOT NULL | Map of `{item_id: quantity}` |
| `order_total` | INTEGER | NOT NULL, CHECK >= 0 | Total coins deducted |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Order timestamp |

**Indexes:** `idx_orders_user_id`, `idx_orders_vendor_id`

---

### `delegates`

Event badge validation. One delegate record per user (maximum).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Record identifier |
| `user_id` | UUID | NOT NULL, FK → users(id) CASCADE | Associated user |
| `delegate_id` | TEXT | NOT NULL, UNIQUE | Badge/ticket ID from event system |
| `validated` | BOOLEAN | NOT NULL, DEFAULT FALSE | Validation status |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Validation timestamp |

**Index:** `idx_delegates_user_id`

---

## Views

### `user_balances`

Computed balance per user: earned coins minus spent coins.

```sql
SELECT
    u.id AS user_id,
    COALESCE(earned.total, 0) - COALESCE(spent.total, 0) AS balance
FROM users u
LEFT JOIN (
    SELECT uc.user_id, SUM(c.value) AS total
    FROM user_coins uc JOIN coins c ON c.id = uc.coin_id
    GROUP BY uc.user_id
) earned ON earned.user_id = u.id
LEFT JOIN (
    SELECT user_id, SUM(order_total) AS total
    FROM orders GROUP BY user_id
) spent ON spent.user_id = u.id
```

| Column | Type | Description |
|--------|------|-------------|
| `user_id` | UUID | User identifier |
| `balance` | INTEGER | Earned coins minus spent coins |

> Balance is never stored — it is always computed from `user_coins` and `orders`.

See [Balance model explainer](explainers/balance-model.md) for details.

---

## Extensions

| Extension | Purpose |
|-----------|---------|
| `pgcrypto` | `gen_random_uuid()` for UUID primary keys |

---

## Applying the Schema

```bash
psql -d merchquest -f backend/schema.sql
psql -d merchquest -f backend/seed.sql
```
