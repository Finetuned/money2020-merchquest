# Testing

The backend has two test suites: **unit tests** (no database) and **integration tests** (real PostgreSQL).

## Unit Tests

**Location:** `frontend/backend/tests/`  
**Count:** 32 tests  
**Runtime:** ~0.06s

Unit tests use FastAPI's `dependency_overrides` and `AsyncMock` to replace all database calls. No PostgreSQL connection is required.

### Run

```bash
cd frontend/backend
source .venv/bin/activate
python -m pytest tests/ --ignore=tests/integration -v
```

### What is tested

| File | Router | Tests |
|------|--------|-------|
| `test_auth.py` | `/api/auth/*` | Guest creation, auth check |
| `test_coins.py` | `/api/*coin*` | Coin listing, collection, duplicate prevention |
| `test_balance.py` | `/api/balance`, `/api/getUsersBalance` | Balance retrieval |
| `test_checkout.py` | `/api/checkout` | Success, insufficient balance, vendor not found |
| `test_vendors.py` | `/api/vendors` | CRUD, delete with stock return |
| `test_vendor_stock.py` | `/api/vendorstock` | Stock query, delivery |
| `test_merch_stock.py` | `/api/merchstock` | CRUD |
| `test_delegates.py` | `/api/*delegate*` | Validation, conflict rules |

---

## Integration Tests

**Location:** `frontend/backend/tests/integration/`  
**Count:** 48 tests  
**Runtime:** ~1s

Integration tests run against a real PostgreSQL database. They verify the full request-to-database round trip, including SQL views, constraints, and transactions.

### Prerequisites

1. PostgreSQL running locally
2. A `merchquest_test` database with the schema applied:

```bash
createdb merchquest_test
psql -d merchquest_test -f backend/schema.sql
```

> The schema only needs to be applied once. The test suite truncates and re-seeds all tables before each test.

### Run

```bash
cd frontend/backend
source .venv/bin/activate
TEST_DATABASE_URL="postgresql://localhost/merchquest_test" \
  python -m pytest tests/integration/ -v
```

Override `TEST_DATABASE_URL` to point at any PostgreSQL instance:

```bash
TEST_DATABASE_URL="postgresql://user:pass@host:5432/merchquest_test" \
  python -m pytest tests/integration/ -v
```

### What is tested

| File | Router | Tests |
|------|--------|-------|
| `test_int_auth.py` | `/api/auth/*` | User inserted into DB; cookie header set; `/me` returns correct state |
| `test_int_coins.py` | `/api/*coin*` | Collection persists in `user_coins`; PK constraint prevents duplicates; 404 on unknown coin |
| `test_int_balance.py` | `/api/balance`, `/api/getUsersBalance` | `user_balances` view computes earned − spent correctly |
| `test_int_checkout.py` | `/api/checkout` | Stock decremented + order recorded atomically; failed checkout leaves DB unchanged |
| `test_int_vendors.py` | `/api/vendors` | Vendor CRUD; delete returns stock to global pool via transaction |
| `test_int_vendor_stock.py` | `/api/vendorstock` | Delivery decrements global pool + upserts vendor stock; insufficient stock rejected |
| `test_int_merch_stock.py` | `/api/merchstock` | Full CRUD; 404 on missing items |
| `test_int_delegates.py` | `/api/*delegate*` | Validation persists; UNIQUE constraint raises 409; one-to-one enforcement |

### What integration tests prove that unit tests cannot

| Behaviour | How it is verified |
|-----------|-------------------|
| `user_balances` view computes correctly | Balance checked via API after inserting `user_coins` and `orders` directly |
| Checkout transaction is atomic | Failed checkout (insufficient balance) leaves `vendor_stock` and `orders` unchanged |
| `delegates.delegate_id` UNIQUE constraint | Second user claiming the same badge ID returns 409 |
| `user_coins` composite PK prevents duplicates | Second `POST /api/addcoin` with same coin returns `success: false` |
| Vendor delete returns stock to global pool | `merch_stock.stock_remaining` verified before and after delete |
| `vendor_stock` upsert on delivery | Delivering to a vendor that already holds stock increments rather than overwrites |

### Test isolation

Each test gets a fresh database state via the `pool` fixture:

1. **Truncate** all tables (`users`, `coins`, `merch_stock`, `vendors` + cascades)
2. **Reset** the `coins_id_seq` sequence to 1
3. **Seed** 3 coins, 2 merch items, and 2 delegate reference IDs
4. **Yield** the pool for the test to use
5. **Close** the pool after the test

Changes made during a test do not affect subsequent tests.

---

## Running Both Suites

```bash
cd frontend/backend
source .venv/bin/activate

# Unit tests (no DB)
python -m pytest tests/ --ignore=tests/integration -v

# Integration tests (requires DB)
TEST_DATABASE_URL="postgresql://localhost/merchquest_test" \
  python -m pytest tests/integration/ -v

# All tests together
TEST_DATABASE_URL="postgresql://localhost/merchquest_test" \
  python -m pytest tests/ -v
```

Expected output: **80 passed** (32 unit + 48 integration).
