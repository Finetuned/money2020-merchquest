# MerchQuest Documentation

Backend documentation for the MerchQuest FastAPI service.

## Contents

### Setup
- [Backend setup](setup/backend.md) — local dev, env vars, running the server, running tests

### Architecture
- [Architecture overview](architecture.md) — system diagram, component roles, request flow
- [Database schema](database.md) — all tables, views, indexes, and constraints

### API Reference
- [API overview](api/README.md) — base URL, authentication, error format
- [Auth](api/auth.md) — guest session creation and identity check
- [Coins](api/coins.md) — coin catalogue and collection
- [Balance](api/balance.md) — coin balance queries
- [Checkout](api/checkout.md) — coin redemption at vendor booths
- [Vendors](api/vendors.md) — vendor management
- [Vendor Stock](api/vendor-stock.md) — per-vendor stock levels and deliveries
- [Merch Stock](api/merch-stock.md) — global merchandise catalogue
- [Delegates](api/delegates.md) — event badge validation

### Explainers
- [QR codes and rot47 encoding](explainers/qr-codes.md)
- [Guest auth session lifecycle](explainers/auth-session.md)
- [Balance model](explainers/balance-model.md)
- [Delegate validation flow](explainers/delegate-validation.md)
- [Checkout flow](explainers/checkout-flow.md)

### Deployment
- [Deployment guide](deployment.md) — Render, DATABASE_URL, CORS, cookies
