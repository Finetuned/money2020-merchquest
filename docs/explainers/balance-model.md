# Balance Model

## Overview

A user's coin balance is never stored as a single value. It is always computed on demand as:

```
balance = earned - spent
```

Where:
- **earned** = sum of `coins.value` for all coins the user has collected
- **spent** = sum of `orders.order_total` for all orders the user has placed

## The `user_balances` View

The database provides a `user_balances` view that computes this for every user:

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

The backend queries this view via `get_user_balance()` in `dependencies.py`:

```python
async def get_user_balance(conn, user_id: str) -> int:
    row = await conn.fetchrow(
        "SELECT balance FROM user_balances WHERE user_id = $1",
        user_id,
    )
    return int(row["balance"]) if row else 0
```

A user with no coins and no orders returns `0`.

## Coin Values

Each coin has a fixed integer value defined in the `coins` table. Values are set when coins are seeded into the database and do not change at runtime.

| Coin | Location | Value |
|------|----------|-------|
| 1 | (seeded) | (seeded) |
| 2 | (seeded) | (seeded) |

See `backend/seed.sql` for the actual values used at the event.

## Balance Invariants

| Invariant | Enforced by |
|-----------|-------------|
| Balance cannot go below zero at checkout | `checkout` router checks `balance >= orderTotal` before proceeding |
| A user can collect each coin at most once | `user_coins` composite primary key `(user_id, coin_id)` |
| Coin values are positive | `coins.value CHECK (value > 0)` |
| Order totals are non-negative | `orders.order_total CHECK (order_total >= 0)` |

## Example

An attendee collects coins worth 10, 5, and 20 coins, then spends 15 coins at a vendor:

```
earned = 10 + 5 + 20 = 35
spent  = 15
balance = 35 - 15 = 20
```

The `user_balances` view returns `20` for this user.
