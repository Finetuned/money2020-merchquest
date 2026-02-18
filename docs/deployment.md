# Deployment Guide

The FastAPI backend is deployed on [Render.com](https://render.com) as a Web Service.

## Environment Variables

Set the following environment variables in the Render dashboard (or equivalent):

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string (e.g. `postgresql://user:pass@host:5432/dbname`) |

Render provides a managed PostgreSQL database. Copy the **Internal Database URL** from the database dashboard into the `DATABASE_URL` environment variable of the web service.

## Render Web Service Configuration

| Setting | Value |
|---------|-------|
| Runtime | Python 3 |
| Build command | `pip install -r requirements.txt` |
| Start command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |
| Root directory | `frontend/backend` |

## CORS

The allowed origins are hardcoded in `main.py`. To add a new frontend origin, update the `allow_origins` list:

```python
allow_origins=[
    "http://localhost:5173",
    "http://localhost:5174",
    "https://money2020-merchquest.netlify.app",
    "https://money2020-vendor.netlify.app",
]
```

Redeploy after any CORS change.

## Cookie Configuration

In production, the `guest_user_id` cookie MUST be set with `secure=True` to ensure it is only sent over HTTPS. Update `routers/auth.py`:

```python
response.set_cookie(
    key="guest_user_id",
    value=user_id,
    domain="<production-domain>",   # e.g. "money2020-merchquest.onrender.com"
    path="/",
    httponly=True,
    samesite="lax",
    secure=True,                    # MUST be True in production
    max_age=60 * 60 * 24 * 30,
)
```

> If the frontend and backend are on different domains, `samesite` may need to be set to `"none"` (which requires `secure=True`).

## Database Setup

Run the schema and seed files against the production database:

```bash
psql "<DATABASE_URL>" -f backend/schema.sql
psql "<DATABASE_URL>" -f backend/seed.sql
```

The `delegate_ids` reference table must also be populated with the event's attendee list before the event begins.

## Health Check

Render performs HTTP health checks. The root path `/` returns a 404 by default (no route is registered). Add a health check endpoint if required:

```python
@app.get("/health")
async def health():
    return {"status": "ok"}
```

## Logs

View application logs in the Render dashboard under **Logs**. The uvicorn access log includes request method, path, status code, and response time.
