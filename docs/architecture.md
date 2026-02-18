# Architecture Overview

## System Components

```
+---------------------+   +---------------------+
|  Customer App       |   |  Vendor CMS          |
|  React 19 + Vite    |   |  React 19 + Vite     |
|  :5173 (dev)        |   |  :5174 (dev)         |
+----------+----------+   +----------+-----------+
           |                          |
           +----------+---------------+
                      | HTTP/REST (cookie auth)
           +----------v---------------+
           |  FastAPI Backend          |
           |  Python 3.14 + asyncpg   |
           |  Render.com (production)  |
           +----------+---------------+
                      |
           +----------v---------------+
           |  PostgreSQL               |
           |  Database: merchquest     |
           +--------------------------+
```

## Component Roles

| Component | Role |
|-----------|------|
| **FastAPI backend** | REST API; manages all business logic, auth, and DB access |
| **PostgreSQL** | Persistent store for users, coins, vendors, stock, orders, delegates |
| **Customer app** | Attendee-facing: scan QR codes, collect coins, view balance, redeem merch |
| **Vendor CMS** | Operator-facing: manage stock, scan attendee QR codes, process checkouts |
| **Unity 3D** | Optional 3D experience; calls the same API for delegate validation |

## Backend Package Structure

```
frontend/backend/
├── main.py              <- app factory: lifespan, CORS, router registration
├── database.py          <- asyncpg pool creation; DATABASE_URL from env
├── models.py            <- Pydantic request/response models
├── dependencies.py      <- shared FastAPI Depends helpers
└── routers/
    ├── auth.py          <- /api/auth/*
    ├── coins.py         <- /api/getcoins, /api/addcoin, etc.
    ├── balance.py       <- /api/balance, /api/getUsersBalance
    ├── checkout.py      <- /api/checkout
    ├── vendors.py       <- /api/vendors
    ├── vendor_stock.py  <- /api/vendorstock
    ├── merch_stock.py   <- /api/merchstock
    └── delegates.py     <- /api/validateDelegate, etc.
```

## Request Flow

```
Client
  |
  | HTTP request (with guest_user_id cookie)
  v
FastAPI router
  |
  | Depends(get_conn)      -> acquires asyncpg connection from pool
  | Depends(current_user)  -> validates cookie, returns user_id
  v
Route handler
  |
  | SQL via asyncpg
  v
PostgreSQL
  |
  v
JSON response
```

## Authentication

All protected endpoints require a `guest_user_id` cookie. The cookie is set by `POST /api/auth/guest` and is HTTP-only, SameSite=Lax. There are no JWT tokens or Authorization headers.

See [Guest auth session lifecycle](explainers/auth-session.md) for full details.

## Database Connection

The asyncpg connection pool is created once at startup via FastAPI's `lifespan` context manager and stored on `app.state.pool`. Each request acquires a connection from the pool via `Depends(get_conn)` and releases it when the response is sent.

See [Database schema](database.md) for the full schema reference.
