# Delegates

Delegate validation links an attendee's guest session to their event badge ID. Each user may validate at most one delegate ID. Each delegate ID may be claimed by at most one user.

See [Delegate validation flow explainer](../explainers/delegate-validation.md) for the full flow.

---

## GET /api/checkDelegateValidated

Checks whether the authenticated user has already validated a delegate ID.

**Auth required:** Yes

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `validated` | boolean | `true` if the user has a delegate record |

### Example

```bash
curl -b cookies.txt http://localhost:8000/api/checkDelegateValidated
```

```json
{ "validated": false }
```

---

## GET /api/checkDelegateIDIsValid

Checks whether a given delegate ID exists in the `delegate_ids` reference table.

**Auth required:** Yes

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `delegateID` | string | Yes | Badge/ticket ID to check |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `valid` | boolean | `true` if the ID exists in the reference table |

### Example

```bash
curl -b cookies.txt "http://localhost:8000/api/checkDelegateIDIsValid?delegateID=BADGE123"
```

```json
{ "valid": true }
```

---

## GET /api/getdelegateIDByUserID

Returns the delegate ID associated with a given user. Used by vendor staff to look up an attendee's badge ID.

**Auth required:** Yes

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userID` | string (UUID) | Yes | Target user's ID |

### Response 200

| Field | Type | Description |
|-------|------|-------------|
| `userID` | string (UUID) | The queried user ID |
| `delegateID` | string | The user's validated delegate ID |

### Response 404

```json
{ "detail": "Delegate not found for user" }
```

### Example

```bash
curl -b cookies.txt "http://localhost:8000/api/getdelegateIDByUserID?userID=a1b2c3d4-..."
```

```json
{
  "userID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "delegateID": "BADGE123"
}
```

---

## POST /api/validateDelegate

Links the authenticated user's session to a delegate ID. The user must not already have a validated delegate, and the delegate ID must not already be claimed by another user.

**Auth required:** Yes

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `delegateID` | string | Yes | Badge/ticket ID to claim |

### Response 200 — success

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `true` |
| `delegateID` | string | The claimed delegate ID |

### Response 200 — already validated

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | `false` |
| `message` | string | `"User already has a validated delegate ID"` |

### Response 409 — delegate ID taken

```json
{ "detail": "Delegate ID already in use" }
```

### Example

```bash
curl -b cookies.txt -X POST http://localhost:8000/api/validateDelegate \
  -H "Content-Type: application/json" \
  -d '{"delegateID": "BADGE123"}'
```

```json
{ "success": true, "delegateID": "BADGE123" }
```
