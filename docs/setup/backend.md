# Backend Setup

The FastAPI backend lives in `frontend/backend/` (within the `frontend` git submodule).

## Prerequisites

- Python 3.12+
- PostgreSQL 14+ running locally
- A database named `merchquest`

## 1. Create the database

```bash
createdb merchquest
psql -d merchquest -f backend/schema.sql
psql -d merchquest -f backend/seed.sql
```

## 2. Create a virtual environment

```bash
cd frontend/backend
python3 -m venv .venv
source .venv/bin/activate        # macOS / Linux
# .venv\Scripts\activate         # Windows
pip install -r requirements.txt
```

## 3. Environment variables

The backend reads one required environment variable:

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://julianweaver@localhost:5432/merchquest` | asyncpg connection string |

Create a `.env` file in `frontend/backend/` (already in `.gitignore`):

```
DATABASE_URL=postgresql://<user>@localhost:5432/merchquest
```

## 4. Run the development server

```bash
cd frontend/backend
source .venv/bin/activate
uvicorn main:app --reload
```

The API will be available at `http://localhost:8000`.
Interactive docs: `http://localhost:8000/docs`

## 5. Run the tests

The test suite uses `pytest-asyncio` and `httpx`. No database connection is required — all DB calls are mocked.

```bash
cd frontend/backend
source .venv/bin/activate
python -m pytest tests/ -v
```

Expected output: **32 passed** in ~0.1s.

## 6. Project structure

```
frontend/backend/
├── main.py              <- app factory
├── database.py          <- asyncpg pool
├── models.py            <- Pydantic models
├── dependencies.py      <- shared Depends helpers
├── requirements.txt     <- Python dependencies
├── pytest.ini           <- test configuration
├── routers/
│   ├── auth.py
│   ├── coins.py
│   ├── balance.py
│   ├── checkout.py
│   ├── vendors.py
│   ├── vendor_stock.py
│   ├── merch_stock.py
│   └── delegates.py
└── tests/
    ├── conftest.py
    ├── test_auth.py
    ├── test_coins.py
    ├── test_balance.py
    ├── test_checkout.py
    ├── test_vendors.py
    ├── test_vendor_stock.py
    ├── test_merch_stock.py
    └── test_delegates.py
```

## Key dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `fastapi` | 0.125.0 | Web framework |
| `uvicorn` | 0.38.0 | ASGI server |
| `asyncpg` | 0.30.0 | Async PostgreSQL driver |
| `pydantic` | 2.12.5 | Request/response validation |
| `python-dotenv` | 1.1.0 | `.env` file loading |
| `pytest` | 9.0.2 | Test runner |
| `pytest-asyncio` | 1.3.0 | Async test support |
| `httpx` | 0.28.1 | Test HTTP client |
