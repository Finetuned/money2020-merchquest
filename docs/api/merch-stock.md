# Merch Stock

The global merchandise catalogue. Defines all items available at the event and their total stock. Items are allocated to vendor booths via the [Vendor Stock](vendor-stock.md) delivery operation.

---

## GET /api/merchstock

Returns all items in the global catalogue.

**Auth required:** No

### Response 200

Array of stock item objects, ordered by ID.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Item slug (e.g. `hat`, `t-shirt`) |
| `price` | integer | Price in coins |
| `stock_remaining` | integer | Total units remaining in the global pool |

### Example

```bash
curl http://localhost:8000/api/merchstock
```

```json
[
  { "id": "hat",     "price": 10, "stock_remaining": 50 },
  { "id": "t-shirt", "price": 20, "stock_remaining": 25 }
]
```

---

## POST /api/merchstock

Adds a new item to the global catalogue.

**Auth required:** No

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Item slug (must be unique) |
| `price` | integer | Yes | Price in coins (>= 0) |
| `stock_remaining` | integer | Yes | Initial global stock (>= 0) |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Item slug |
| `price` | integer | Price in coins |
| `stock_remaining` | integer | Initial stock |

### Example

```bash
curl -X POST http://localhost:8000/api/merchstock \
  -H "Content-Type: application/json" \
  -d '{"id": "cap", "price": 8, "stock_remaining": 30}'
```

```json
{ "id": "cap", "price": 8, "stock_remaining": 30 }
```

---

## PUT /api/merchstock/{item_id}

Updates the price and/or stock level of an existing item.

**Auth required:** No

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `item_id` | string | Item slug to update |

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Item slug (ignored in update, path param takes precedence) |
| `price` | integer | Yes | New price in coins |
| `stock_remaining` | integer | Yes | New global stock level |

### Response 200

Updated item object (same shape as GET response).

### Response 404

```json
{ "detail": "Item '<item_id>' not found" }
```

### Example

```bash
curl -X PUT http://localhost:8000/api/merchstock/hat \
  -H "Content-Type: application/json" \
  -d '{"id": "hat", "price": 12, "stock_remaining": 40}'
```

```json
{ "id": "hat", "price": 12, "stock_remaining": 40 }
```

---

## DELETE /api/merchstock/{item_id}

Removes an item from the global catalogue.

**Auth required:** No

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `item_id` | string | Item slug to delete |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `true` |
| `deleted_id` | string | The deleted item slug |

### Response 404

```json
{ "detail": "Item '<item_id>' not found" }
```

### Example

```bash
curl -X DELETE http://localhost:8000/api/merchstock/cap
```

```json
{ "success": true, "deleted_id": "cap" }
```
