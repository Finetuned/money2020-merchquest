# Checkout

## POST /api/checkout

Redeems coins for merchandise at a vendor booth. Deducts the order total from the user's balance, decrements vendor stock, and records the order.

**Auth required:** No (user ID is taken from the request body, not the cookie — see note below)

> **Note:** The `userID` field in the request body is the attendee's user ID, scanned by the vendor from the attendee's QR code. The vendor operator's own session cookie is used for authentication.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userID` | string (UUID) | Yes | Attendee's user ID |
| `vendorID` | string (UUID) | Yes | Vendor booth ID |
| `items` | object | Yes | Map of `{ "item_id": quantity }` |
| `orderTotal` | integer | Yes | Total coins to deduct |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `true` |
| `remaining_balance` | integer | Attendee's balance after the transaction |

### Response 400 — insufficient balance

```json
{ "detail": "Insufficient balance" }
```

### Response 400 — insufficient vendor stock

```json
{ "detail": "Insufficient vendor stock for <item_id>" }
```

### Response 404 — vendor not found

```json
{ "detail": "Vendor not found" }
```

### Example

```bash
curl -b cookies.txt -X POST http://localhost:8000/api/checkout \
  -H "Content-Type: application/json" \
  -d '{
    "userID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "vendorID": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "items": { "hat": 1, "t-shirt": 2 },
    "orderTotal": 30
  }'
```

```json
{ "success": true, "remaining_balance": 12 }
```

### Transaction behaviour

The checkout runs inside a database transaction:

1. Verify the attendee has sufficient balance.
2. Verify the vendor exists.
3. Verify the vendor holds sufficient stock for each item.
4. Decrement `vendor_stock.quantity` for each item.
5. Insert a row into `orders`.
6. Return the updated balance.

If any step fails, the transaction is rolled back and no changes are persisted.

See [Checkout flow explainer](../explainers/checkout-flow.md) for a full sequence diagram.
