# Auth

## POST /api/auth/guest

Creates a new anonymous guest session and sets the auth cookie.

**Auth required:** No

### Request

No body required.

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | string (UUID) | Newly created user ID |
| `is_guest` | boolean | Always `true` |

### Set-Cookie

```
guest_user_id=<uuid>; HttpOnly; Path=/; SameSite=Lax; Max-Age=2592000
```

Max-Age is 30 days. The cookie is not `Secure` in development; set `secure=True` in production.

### Example

```bash
curl -c cookies.txt -X POST http://localhost:8000/api/auth/guest
```

```json
{
  "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "is_guest": true
}
```

---

## GET /api/auth/me

Returns the identity of the currently authenticated user.

**Auth required:** No (returns `authenticated: false` if no cookie present)

### Request

No body required. The `guest_user_id` cookie is read automatically.

### Response 200 — authenticated

| Field | Type | Description |
|-------|------|-------------|
| `authenticated` | boolean | `true` |
| `user_id` | string (UUID) | The user's ID from the cookie |
| `is_guest` | boolean | Always `true` |

### Response 200 — unauthenticated

| Field | Type | Description |
|-------|------|-------------|
| `authenticated` | boolean | `false` |

### Example

```bash
curl -b cookies.txt http://localhost:8000/api/auth/me
```

```json
{
  "authenticated": true,
  "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "is_guest": true
}
```
