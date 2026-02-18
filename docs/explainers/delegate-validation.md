# Delegate Validation Flow

## Overview

Delegate validation links an attendee's anonymous guest session to their physical event badge. The badge carries a unique `delegate_id` (e.g. a ticket reference or badge number). Once validated, the attendee's identity is tied to their badge for the duration of the event.

## Why Validation Exists

The event system issues physical badges with unique IDs. Validation serves two purposes:

1. **Identity binding** — associates a guest UUID with a real-world badge, enabling vendor staff to look up an attendee by scanning their badge QR code.
2. **One-to-one constraint** — each badge ID can only be claimed by one user, and each user can only claim one badge ID.

## Data Model

```
users (id UUID)
  |
  | 1:0..1
  v
delegates (user_id UUID, delegate_id TEXT UNIQUE)
```

A `delegates` row is created when a user successfully validates. The `delegate_id` column has a `UNIQUE` constraint, enforcing the one-to-one relationship at the database level.

## Validation Flow

```
Attendee                    App                         Server
    |                        |                              |
    | Enters / scans badge ID |                              |
    |----------------------->|                              |
    |                        | GET /api/checkDelegateValidated
    |                        |----------------------------->|
    |                        | { validated: false }         |
    |                        |<-----------------------------|
    |                        |                              |
    |                        | GET /api/checkDelegateIDIsValid?delegateID=...
    |                        |----------------------------->|
    |                        | { valid: true }              |
    |                        |<-----------------------------|
    |                        |                              |
    |                        | POST /api/validateDelegate   |
    |                        | { "delegateID": "BADGE123" } |
    |                        |----------------------------->|
    |                        |                              | Check: user already validated?
    |                        |                              | Check: delegate_id already taken?
    |                        |                              | INSERT INTO delegates
    |                        | { success: true }            |
    |                        |<-----------------------------|
    | Validation confirmed   |                              |
    |<-----------------------|                              |
```

## Conflict Rules

| Scenario | Outcome |
|----------|---------|
| User already has a validated delegate | `200 { success: false, message: "User already has a validated delegate ID" }` |
| Delegate ID already claimed by another user | `409 { detail: "Delegate ID already in use" }` |
| Delegate ID does not exist in reference table | `{ valid: false }` from `checkDelegateIDIsValid` (client should block before calling `validateDelegate`) |
| Success | `200 { success: true, delegateID: "..." }` |

## Looking Up a Delegate

Vendor staff can look up an attendee's delegate ID by their user ID:

```
GET /api/getdelegateIDByUserID?userID=<uuid>
-> { "userID": "...", "delegateID": "BADGE123" }
```

This is used when a vendor scans an attendee's QR code (which encodes the user UUID) and needs to cross-reference their badge.

## Reference Table

The `delegate_ids` table (not defined in `schema.sql`) is a pre-populated reference table of valid badge IDs issued by the event system. `GET /api/checkDelegateIDIsValid` queries this table to verify a badge ID before validation is attempted.

> **Note:** The `delegate_ids` table must be populated separately from the main schema, typically by importing the event's attendee list.
