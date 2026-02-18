# Balance

Balance is computed dynamically from collected coins minus spent coins. It is never stored directly. See [Balance model explainer](../explainers/balance-model.md).

---

## GET /api/balance

Returns the coin balance of the authenticated user.

**Auth required:** Yes

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `balance` | integer | Current balance in coins (earned minus spent) |

### Example

```bash
curl -b cookies.txt http://localhost:8000/api/balance
```

```json
{ "balance": 42 }
```

---

## GET /api/getUsersBalance

Returns the coin balance of any user by their ID. Used by vendor staff to check an attendee's balance before checkout.

**Auth required:** Yes

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userID` | string (UUID) | Yes | Target user's ID |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `userID` | string (UUID) | The queried user ID |
| `user_balance` | integer | Balance in coins |

### Example

```bash
curl -b cookies.txt "http://localhost:8000/api/getUsersBalance?userID=a1b2c3d4-..."
```

```json
{
  "userID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "user_balance": 25
}
```
