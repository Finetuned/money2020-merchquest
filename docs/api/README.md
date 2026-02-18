# API Overview

## Base URL

| Environment | URL |
|-------------|-----|
| Local dev | `http://localhost:8000` |
| Production | `https://money2020-merchquest.onrender.com` |

Interactive docs (Swagger UI): `{base_url}/docs`

## Authentication

All protected endpoints require a `guest_user_id` cookie. Obtain one by calling `POST /api/auth/guest`.

```
Cookie: guest_user_id=<uuid>
```

Endpoints that require auth are marked **Auth required** in each page. Unauthenticated requests to protected endpoints return:

```json
HTTP 401
{ "detail": "User not authenticated" }
```

## Error Format

All errors follow FastAPI's standard format:

```json
{
  "detail": "Human-readable error message"
}
```

| Status | Meaning |
|--------|---------|
| 400 | Bad request (e.g. insufficient balance, invalid quantity) |
| 401 | Missing or invalid `guest_user_id` cookie |
| 404 | Resource not found |
| 409 | Conflict (e.g. delegate ID already in use) |
| 422 | Request body validation failed (Pydantic) |
| 500 | Internal server error |

## Content Type

All request bodies MUST be `application/json`. All responses are `application/json`.

## CORS

The API allows cross-origin requests from:

- `http://localhost:5173`
- `http://localhost:5174`
- `https://money2020-merchquest.netlify.app`
- `https://money2020-vendor.netlify.app`

Credentials (cookies) are included in CORS requests.

## Endpoints

| Tag | Endpoints |
|-----|-----------|
| [Auth](auth.md) | `POST /api/auth/guest` · `GET /api/auth/me` |
| [Coins](coins.md) | `GET /api/getcoins` · `POST /api/addcoin` · `GET /api/getmycoins` · `GET /api/checkuserhascoin` · `GET /api/getcustomerscoins` |
| [Balance](balance.md) | `GET /api/balance` · `GET /api/getUsersBalance` |
| [Checkout](checkout.md) | `POST /api/checkout` |
| [Vendors](vendors.md) | `GET /api/vendors` · `POST /api/vendors` · `DELETE /api/vendors/{id}` |
| [Vendor Stock](vendor-stock.md) | `GET /api/vendorstock` · `POST /api/vendorstock` |
| [Merch Stock](merch-stock.md) | `GET /api/merchstock` · `POST /api/merchstock` · `PUT /api/merchstock/{id}` · `DELETE /api/merchstock/{id}` |
| [Delegates](delegates.md) | `GET /api/checkDelegateValidated` · `GET /api/checkDelegateIDIsValid` · `GET /api/getdelegateIDByUserID` · `POST /api/validateDelegate` |
