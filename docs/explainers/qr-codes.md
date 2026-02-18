# QR Codes and rot47 Encoding

## Overview

Each collectible coin is associated with a physical QR code placed at an event location. When an attendee scans the QR code, the app decodes the payload and calls `POST /api/addcoin` to record the collection.

## QR Payload Format

The raw QR code value is a rot47-encoded string. When decoded, it produces a plain-text payload in the following format:

```
<coin_id>
```

Where `coin_id` is the integer ID of the coin (matching `coins.id` in the database).

### Example

| Coin ID | Encoded QR value |
|---------|-----------------|
| `0` | `_` |
| `1` | `` ` `` |
| `2` | `a` |

> The exact encoded values depend on the rot47 implementation. See `frontend/www/src/lib/rot47Cipher.js` for the client-side decoder.

## rot47 Cipher

rot47 is a simple substitution cipher that rotates printable ASCII characters (codes 33–126) by 47 positions. It is symmetric: encoding and decoding use the same function.

```
encoded_char = ((char_code - 33 + 47) % 94) + 33
```

### Properties

- Symmetric: `rot47(rot47(x)) === x`
- Operates only on printable ASCII (! through ~)
- Spaces and non-printable characters are passed through unchanged

### Purpose in MerchQuest

rot47 is used as a lightweight obfuscation layer to prevent attendees from trivially guessing coin IDs by inspecting QR codes. It is not a security mechanism — the coin IDs are sequential integers and the cipher is publicly known.

## QR Code Files

Pre-generated QR code images are stored in `frontend/qr_codes/`:

```
frontend/qr_codes/
├── m2020merch_coin0.png
├── m2020merch_coin1.png
└── m2020merch_coin2.png
```

Each file name corresponds to the coin's zero-based index. The QR code encodes the rot47-encoded coin ID.

## Collection Flow

```
Attendee scans QR code
        |
        v
App decodes rot47 payload -> coin_id (integer)
        |
        v
POST /api/addcoin  { "coin_id": <n> }
        |
        +-- coin already owned? -> { "success": false }
        |
        +-- coin not found?     -> 404
        |
        v
INSERT INTO user_coins (user_id, coin_id)
        |
        v
{ "success": true, "coin_id": <n> }
```
