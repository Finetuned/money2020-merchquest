# Coins

## GET /api/getcoins

Returns the full catalogue of collectible coins.

**Auth required:** No

### Response 200

Array of coin objects.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Coin ID (1-based sequential) |
| `locationref` | string | Human-readable event location label |
| `value` | integer | Coin value in coins currency |
| `glbRef` | string | Path/URL to the 3D GLB asset |

### Example

```bash
curl http://localhost:8000/api/getcoins
```

```json
[
  { "id": 1, "locationref": "Main Stage", "value": 10, "glbRef": "coins/coin1.glb" },
  { "id": 2, "locationref": "Expo Hall", "value": 5,  "glbRef": "coins/coin2.glb" }
]
```

---

## POST /api/addcoin

Records that the authenticated user has collected a coin.

**Auth required:** Yes

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `coin_id` | integer | Yes | ID of the coin to collect |

### Response 200 — success

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `true` |
| `coin_id` | integer | The collected coin ID |

### Response 200 — already owned

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `false` |
| `message` | string | `"User already has this coin"` |

### Response 404

Coin ID does not exist.

### Example

```bash
curl -b cookies.txt -X POST http://localhost:8000/api/addcoin \
  -H "Content-Type: application/json" \
  -d '{"coin_id": 1}'
```

```json
{ "success": true, "coin_id": 1 }
```

---

## GET /api/getmycoins

Returns all coins collected by the authenticated user.

**Auth required:** Yes

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `users_collection` | array | Array of coin objects (same shape as `/api/getcoins`) |

### Example

```bash
curl -b cookies.txt http://localhost:8000/api/getmycoins
```

```json
{
  "users_collection": [
    { "id": 1, "locationref": "Main Stage", "value": 10, "glbRef": "coins/coin1.glb" }
  ]
}
```

---

## GET /api/checkuserhascoin

Checks whether the authenticated user has collected a specific coin.

**Auth required:** Yes

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `coin_id` | integer | Yes | Coin ID to check |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `has_coin` | boolean | `true` if the user owns this coin |

### Example

```bash
curl -b cookies.txt "http://localhost:8000/api/checkuserhascoin?coin_id=1"
```

```json
{ "has_coin": true }
```

---

## GET /api/getcustomerscoins

Returns all coins collected by a specific user (by user ID). Used by vendor staff to view an attendee's collection.

**Auth required:** Yes

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `customerID` | string (UUID) | Yes | Target user's ID |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `users_collection` | array | Array of coin objects collected by the target user |

### Example

```bash
curl -b cookies.txt "http://localhost:8000/api/getcustomerscoins?customerID=a1b2c3d4-..."
```

```json
{
  "users_collection": [
    { "id": 2, "locationref": "Expo Hall", "value": 5, "glbRef": "coins/coin2.glb" }
  ]
}
```
