# Vendor Stock

Vendor stock tracks how many units of each item a specific vendor booth currently holds. Items are allocated from the global `merch_stock` pool via a delivery operation.

---

## GET /api/vendorstock

Returns the current stock levels for a vendor, showing both vendor-held quantity and global pool quantity for every item in the catalogue.

**Auth required:** No

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `vendorID` | string (UUID) | Yes | Vendor to query |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `vendorID` | string (UUID) | The queried vendor ID |
| `stock` | object | Map of `{ "item_id": { "vendor": n, "global": n } }` |

`vendor` is the quantity held by this vendor. `global` is the total remaining in the global pool (`merch_stock.stock_remaining`).

### Response 404

```json
{ "detail": "Vendor not found" }
```

### Example

```bash
curl "http://localhost:8000/api/vendorstock?vendorID=b2c3d4e5-..."
```

```json
{
  "vendorID": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "stock": {
    "hat":    { "vendor": 5, "global": 45 },
    "t-shirt": { "vendor": 2, "global": 18 }
  }
}
```

---

## POST /api/vendorstock

Delivers items from the global stock pool to a vendor booth. Decrements `merch_stock.stock_remaining` and increments `vendor_stock.quantity` for each item.

**Auth required:** No

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `vendorID` | string (UUID) | Yes | Destination vendor |
| `deliveries` | object | Yes | Map of `{ "item_id": quantity }` to deliver |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `true` |
| `vendorID` | string (UUID) | The vendor that received the delivery |

### Response 400 — insufficient global stock

```json
{ "detail": "Not enough global stock for '<item_id>'" }
```

### Response 400 — invalid quantity

```json
{ "detail": "Invalid quantity" }
```

### Response 404 — vendor not found

```json
{ "detail": "Vendor not found" }
```

### Response 404 — item not found

```json
{ "detail": "Item '<item_id>' not found" }
```

### Example

```bash
curl -X POST http://localhost:8000/api/vendorstock \
  -H "Content-Type: application/json" \
  -d '{
    "vendorID": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "deliveries": { "hat": 10, "t-shirt": 5 }
  }'
```

```json
{ "success": true, "vendorID": "b2c3d4e5-f6a7-8901-bcde-f12345678901" }
```

### Transaction behaviour

The delivery runs inside a database transaction:

1. Validate the vendor exists.
2. For each item: verify it exists in `merch_stock`, quantity is non-negative, and global stock is sufficient.
3. Upsert `vendor_stock` (insert or increment quantity).
4. Decrement `merch_stock.stock_remaining`.

If any step fails, the transaction is rolled back.
