# Guest Auth Session Lifecycle

## Overview

MerchQuest uses anonymous guest sessions. There are no passwords, email addresses, or OAuth flows. Every attendee is identified by a UUID stored in an HTTP-only cookie.

## Session Creation

```
Client                          Server                      Database
  |                               |                             |
  | POST /api/auth/guest          |                             |
  |------------------------------>|                             |
  |                               | gen_random_uuid()           |
  |                               | INSERT INTO users (id)      |
  |                               |---------------------------->|
  |                               |<----------------------------|
  |                               |                             |
  | 200 { user_id, is_guest }     |                             |
  | Set-Cookie: guest_user_id=... |                             |
  |<------------------------------|                             |
```

A new UUID is generated server-side and inserted into the `users` table. The UUID is returned in the response body and also set as an HTTP-only cookie.

## Cookie Properties

| Property | Value | Notes |
|----------|-------|-------|
| Name | `guest_user_id` | |
| Value | UUID string | e.g. `a1b2c3d4-e5f6-7890-abcd-ef1234567890` |
| HttpOnly | `true` | Not accessible via JavaScript |
| Path | `/` | Sent with all requests |
| SameSite | `Lax` | Sent on same-site navigations and top-level cross-site GETs |
| Secure | `false` (dev) | MUST be `true` in production over HTTPS |
| Max-Age | `2592000` | 30 days |
| Domain | `localhost` (dev) | Set to production domain in deployment |

## Authenticated Requests

Every request that requires authentication reads the `guest_user_id` cookie via FastAPI's `Cookie` dependency:

```python
async def current_user(guest_user_id: Optional[str] = Cookie(None)) -> str:
    if not guest_user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    return guest_user_id
```

The cookie value (the UUID string) is used directly as the `user_id` in all database queries. There is no token validation or signature verification — the UUID itself is the credential.

## Identity Check

`GET /api/auth/me` reads the cookie and returns the user's identity without touching the database:

```python
async def get_current_user(guest_user_id: Optional[str] = Cookie(None)):
    if not guest_user_id:
        return {"authenticated": False}
    return {"authenticated": True, "user_id": guest_user_id, "is_guest": True}
```

## Session Expiry

Sessions expire when the cookie's `Max-Age` (30 days) elapses. There is no server-side session store — the cookie is the only record of the session. If the cookie is deleted or expires, the user's data (coins, balance, orders) remains in the database but is inaccessible without the original UUID.

## Security Considerations

| Concern | Mitigation |
|---------|-----------|
| Cookie theft | `HttpOnly` prevents JavaScript access; use `Secure` + HTTPS in production |
| UUID guessing | UUIDs are 128-bit random values; brute-force is not feasible |
| CSRF | `SameSite=Lax` mitigates most CSRF vectors |
| No server-side revocation | Sessions cannot be invalidated server-side; cookie deletion is the only logout mechanism |
