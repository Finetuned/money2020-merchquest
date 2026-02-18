# Checkout Flow

## Overview

Checkout is the process by which an attendee redeems coins for merchandise at a vendor booth. The vendor operator scans the attendee's QR code to obtain their user ID, selects items, and submits the order via `POST /api/checkout`.

## Actors

| Actor | Role |
|-------|------|
| Attendee | Provides their user ID (via QR code) and coins |
| Vendor operator | Scans QR code, selects items, submits checkout |
| Vendor CMS | Calls the API on behalf of the operator |

## Sequence Diagram

```
Vendor CMS                          Server                        Database
    |                                  |                               |
    | POST /api/checkout               |                               |
    | { userID, vendorID,              |                               |
    |   items, orderTotal }            |                               |
    |--------------------------------->|                               |
    |                                  |                               |
    |                                  | SELECT balance                |
    |                                  | FROM user_balances            |
    |                                  | WHERE user_id = userID        |
    |                                  |------------------------------>|
    |                                  |<------------------------------|
    |                                  |                               |
    |                                  | balance < orderTotal?         |
    |                                  | -> 400 Insufficient balance   |
    |                                  |                               |
    |                                  | SELECT id FROM vendors        |
    |                                  | WHERE id = vendorID           |
    |                                  |------------------------------>|
    |                                  |<------------------------------|
    |                                  |                               |
    |                                  | vendor not found?             |
    |                                  | -> 404 Vendor not found       |
    |                                  |                               |
    |                                  | For each item in items:       |
    |                                  | SELECT quantity               |
    |                                  | FROM vendor_stock             |
    |                                  | WHERE vendor_id = vendorID    |
    |                                  | AND stock_item_id = item_id   |
    |                                  |------------------------------>|
    |                                  |<------------------------------|
    |                                  |                               |
    |                                  | qty > available?              |
    |                                  | -> 400 Insufficient stock     |
    |                                  |                               |
    |                                  | BEGIN TRANSACTION             |
    |                                  |------------------------------>|
    |                                  |                               |
    |                                  | For each item:                |
    |                                  | UPDATE vendor_stock           |
    |                                  | SET quantity = quantity - qty |
    |                                  |------------------------------>|
    |                                  |                               |
    |                                  | INSERT INTO orders            |
    |                                  | (user_id, vendor_id,          |
    |                                  |  items, order_total)          |
    |                                  |------------------------------>|
    |                                  |                               |
    |                                  | COMMIT                        |
    |                                  |------------------------------>|
    |                                  |<------------------------------|
    |                                  |                               |
    |                                  | SELECT balance                |
    |                                  | FROM user_balances            |
    |                                  | WHERE user_id = userID        |
    |                                  |------------------------------>|
    |                                  |<------------------------------|
    |                                  |                               |
    | 200 { success: true,             |                               |
    |       remaining_balance }        |                               |
    |<---------------------------------|                               |
```

## Validation Steps

All validation occurs **before** the transaction begins. If any check fails, no database writes occur.

| Step | Check | Error |
|------|-------|-------|
| 1 | `balance >= orderTotal` | `400 Insufficient balance` |
| 2 | Vendor exists | `404 Vendor not found` |
| 3 | For each item: `vendor_stock.quantity >= requested_qty` | `400 Insufficient vendor stock for <item_id>` |

## Transaction Scope

The following writes are wrapped in a single database transaction:

1. `UPDATE vendor_stock SET quantity = quantity - qty` for each item
2. `INSERT INTO orders (user_id, vendor_id, items, order_total)`

If either write fails (e.g. a concurrent checkout depletes stock), the transaction is rolled back and the attendee's balance is unchanged.

## Stock Flow

```
Global pool (merch_stock.stock_remaining)
        |
        | POST /api/vendorstock (delivery)
        v
Vendor pool (vendor_stock.quantity)
        |
        | POST /api/checkout
        v
Sold (order recorded, stock decremented)
```

Stock flows in one direction: global → vendor → sold. When a vendor is deleted, any unsold vendor stock is returned to the global pool.

## Notes

- `orderTotal` in the request body is the client-computed total. The server does not independently verify that `orderTotal` equals the sum of item prices × quantities. The client is responsible for computing the correct total.
- The balance check uses the `user_balances` view, which is computed from `user_coins` and `orders` at query time.
