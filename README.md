# MerchQuest — Money20/20 Merchandise Experience

A gamified merchandise experience for the Money20/20 conference. Delegates scan QR codes around the venue to collect virtual coins, then redeem them for merchandise at vendor booths. A Unity 3D experience provides an additional interactive layer.

---

## Architecture

```
┌─────────────────────┐   ┌─────────────────────┐
│  Customer App        │   │  Vendor CMS          │
│  frontend/www/       │   │  frontend/www_vendor/│
│  React 19 + Vite     │   │  React 19 + Vite     │
│  Port 5173           │   │  Port 5174           │
└────────┬────────────┘   └────────┬────────────┘
         │                          │
         └──────────┬───────────────┘
                    │ HTTP (cookie auth)
         ┌──────────▼───────────────┐
         │  FastAPI Backend          │
         │  frontend/backend/        │
         │  Python + asyncpg         │
         │  Render.com               │
         └──────────┬───────────────┘
                    │
         ┌──────────▼───────────────┐
         │  PostgreSQL               │
         │  Database: merchquest     │
         └──────────────────────────┘

         ┌──────────────────────────┐
         │  Unity 3D                 │
         │  frontend/unity/          │
         │  URP (mobile-optimised)   │
         └──────────────────────────┘
```

---

## Repository Structure

This is the **root repository**. The full project codebase lives in `frontend/` as a **git submodule**.

```
merchquest/                     ← root repo (this repo)
├── README.md
├── .gitmodules                 ← submodule config
├── backend/
│   ├── schema.sql              ← PostgreSQL schema (run once to set up DB)
│   └── seed.sql                ← seed data (6 coins + merch stock)
├── fastapi/
│   └── openapi.json            ← OpenAPI 3.1.0 schema (source of truth)
└── frontend/                   ← git submodule (danhodgkins/money2020_MerchQuest)
    ├── backend/
    │   ├── main.py             ← FastAPI app (asyncpg + PostgreSQL)
    │   └── requirements.txt
    ├── www/                    ← Customer React app
    ├── www_vendor/             ← Vendor CMS React app
    ├── unity/m2020merch/       ← Unity 3D project
    └── qr_codes/               ← QR code PNGs for coins
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 20+ |
| Python | 3.11+ |
| PostgreSQL | 14+ |
| Unity | 6 (URP) |

---

## Database Setup

Run once against a local or hosted PostgreSQL instance:

```bash
psql -U julianweaver -d merchquest -f backend/schema.sql
psql -U julianweaver -d merchquest -f backend/seed.sql
```

This creates 7 tables (`users`, `delegates`, `coins`, `user_coins`, `vendors`, `merch_stock`, `vendor_stock`, `orders`), a `user_balances` view, and seeds 6 collectible coins.

> **Note:** The seed inserts coins with PostgreSQL SERIAL IDs (starting at 1). If QR codes encode 0-based coin IDs, verify with `SELECT id, locationref FROM coins;` and re-seed with explicit IDs if needed.

---

## Local Development

### 1. Backend (FastAPI)

```bash
cd frontend/backend

# Create virtual environment (first time only)
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run (uses DATABASE_URL env var, defaults to localhost)
uvicorn main:app --reload
# → http://localhost:8000
```

The backend defaults to `postgresql://julianweaver@localhost:5432/merchquest`. Override by setting `DATABASE_URL` in a `.env` file:

```
DATABASE_URL=postgresql://user:password@host:5432/merchquest
```

### 2. Customer App

```bash
cd frontend/www
npm install
npm run dev
# → http://localhost:5173
```

### 3. Vendor CMS

```bash
cd frontend/www_vendor
npm install
npm run dev
# → http://localhost:5174
```

### 4. Unity

Open `frontend/unity/m2020merch/` in Unity 6 with URP. The project targets mobile (iOS/Android).

---

## Documentation

Full backend documentation is in [`docs/`](docs/README.md):

- [Architecture overview](docs/architecture.md)
- [Database schema](docs/database.md)
- [Backend setup](docs/setup/backend.md)
- [API reference](docs/api/README.md)
- [Explainers](docs/explainers/qr-codes.md) — QR codes, auth sessions, balance model, delegate validation, checkout flow
- [Deployment guide](docs/deployment.md)

---

## API Reference

| Environment | Base URL |
|-------------|----------|
| Production | https://money2020-merchquest.onrender.com |
| Local | http://localhost:8000 |

- **OpenAPI schema**: `fastapi/openapi.json` or https://money2020-merchquest.onrender.com/openapi.json
- **Auth**: Cookie-based (`guest_user_id` HTTP-only cookie). All protected endpoints require the cookie. Call `POST /api/auth/guest` to create a session.
- **Balance**: Computed dynamically — coins collected minus coins spent on orders.

### Key Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/auth/guest` | Create guest session (sets cookie) |
| `GET` | `/api/auth/me` | Check authentication status |
| `GET` | `/api/getcoins` | List all collectible coins |
| `POST` | `/api/addcoin` | Collect a coin (by coin_id) |
| `GET` | `/api/getmycoins` | Get current user's collected coins |
| `GET` | `/api/balance` | Get current user's coin balance |
| `POST` | `/api/validateDelegate` | Link delegate badge ID to user |
| `GET` | `/api/vendors` | List all vendors |
| `GET` | `/api/vendorstock` | Get vendor stock levels |
| `POST` | `/api/vendorstock` | Deliver stock to a vendor |
| `GET` | `/api/merchstock` | List global merchandise catalogue |
| `POST` | `/api/checkout` | Redeem coins for merchandise |

---

## Git Submodule Workflow

Changes to the application code MUST be committed from inside `frontend/`:

```bash
# Make changes inside frontend/
cd frontend
git add .
git commit -m "your message"
git push

# Then update the submodule reference in the root repo
cd ..
git add frontend
git commit -m "update submodule ref"
git push
```

To pull the latest submodule changes:

```bash
git submodule update --remote frontend
```

---

## Deployment (Render)

1. Set the `DATABASE_URL` environment variable on Render to point to your PostgreSQL instance
2. The backend reads `DATABASE_URL` automatically via `python-dotenv`
3. Update `domain` in the `set_cookie` call in `main.py` and set `secure=True` for HTTPS
4. Add any additional production domains to the `allow_origins` CORS list in `main.py`