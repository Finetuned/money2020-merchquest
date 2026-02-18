# Vendors

## GET /api/vendors

Returns all vendor booths, ordered by creation time.

**Auth required:** No

### Response 200

Array of vendor objects.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Vendor identifier |
| `name` | string | Display name |

### Example

```bash
curl http://localhost:8000/api/vendors
```

```json
[
  { "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901", "name": "Merch Booth A" },
  { "id": "c3d4e5f6-a7b8-9012-cdef-123456789012", "name": "Merch Booth B" }
]
```

---

## POST /api/vendors

Creates a new vendor booth.

**Auth required:** No

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Vendor display name (leading/trailing whitespace is stripped) |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Newly created vendor ID |
| `name` | string | Vendor name |

### Example

```bash
curl -X POST http://localhost:8000/api/vendors \
  -H "Content-Type: application/json" \
  -d '{"name": "Merch Booth C"}'
```

```json
{ "id": "d4e5f6a7-b8c9-0123-defa-234567890123", "name": "Merch Booth C" }
```

---

## DELETE /api/vendors/{vendor_id}

Deletes a vendor booth. Any stock held by the vendor is returned to the global `merch_stock` pool before deletion.

**Auth required:** No

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `vendor_id` | string (UUID) | Vendor to delete |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `true` |
| `vendor_id` | string (UUID) | Deleted vendor ID |
| `returned_to_global_stock` | object | Map of `{ "item_id": quantity }` returned to global stock |

### Response 404

```json
{ "detail": "Vendor not found" }
```

### Example

```bash
curl -X DELETE http://localhost:8000/api/vendors/b2c3d4e5-f6a7-8901-bcde-f12345678901
```

```json
{
  "success": true,
  "vendor_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "returned_to_global_stock": { "hat": 3, "t-shirt": 1 }
}
```

### Transaction behaviour

The delete runs inside a database transaction:

1. Return all vendor stock quantities to `merch_stock.stock_remaining`.
2. Delete all rows from `vendor_stock` for this vendor.
3. Delete the vendor row.

If any step fails, the transaction is rolled back.
