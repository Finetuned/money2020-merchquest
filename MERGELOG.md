# Merge Log

## 2026-02-21 - Frontend Merge Validation Follow-up

Scope: Fix regressions found after validating merge commit `7628431` in `frontend/`.

### Files changed in `frontend/`

1. `www/src/routes/Scanner/index.jsx`
- Request body key changed from `delegateID` to `delegateId` for `POST /api/validateDelegate`.
- This MUST match backend alias requirements (`delegateId`).

2. `www_vendor/src/routes/Scanner/index.jsx`
- Response field usage changed from `responseObj.userID` to `responseObj.userId`.
- Internal variable `userIDToCheck` renamed to `userIdToCheck` for consistency.
- Legacy commented references were updated to match `userId` naming.

3. `www_vendor/src/components/ui/select.jsx`
- Import changed from `radix-ui` to `@radix-ui/react-select`.
- This MUST resolve to the actual Radix Select package used by the component API.

4. `unity/m2020merch/Assets/Scripts/UI/Sandbox/Checkout.cs`
- `OrderRequest` payload fields changed:
  - `userID` -> `userId`
  - `vendorID` -> `vendorId`
- Request object creation updated to use the new field names.

5. `unity/m2020merch/Assets/Scripts/UI/Sandbox/ValidateDelegate.cs`
- Request and response DTO fields changed:
  - `delegateID` -> `delegateId`
  - `userID` -> `userId`
- Response reads and logs updated to use `userId`/`delegateId`.

6. `unity/m2020merch/Assets/Scripts/UI/Sandbox/CheckDelegateValidated.cs`
- Query string changed:
  - `/api/checkDelegateIDIsValid?delegateID=...` -> `/api/checkDelegateIDIsValid?delegateId=...`
- Response reads/logs changed:
  - `response.userID` -> `response.userId`

7. `unity/m2020merch/Assets/Scripts/UI/Sandbox/GetVendorMerch.cs`
- Query string changed:
  - `/api/vendorstock?vendorID=...` -> `/api/vendorstock?vendorId=...`
- Response DTO field changed:
  - `vendorID` -> `vendorId`
- Commented log reference updated to `response.vendorId`.

8. `unity/m2020merch/Assets/Scripts/UI/DelegateUI/DelegateRedeemController.cs`
- Query string changed:
  - `/api/vendorstock?vendorID=...` -> `/api/vendorstock?vendorId=...`
- Response DTO field changed:
  - `vendorID` -> `vendorId`
- Related variable names/comments updated for consistency.

9. `unity/m2020merch/Assets/Scripts/UI/DelegateUI/DelegatePanelController.cs`
- Query string changed:
  - `/api/checkDelegateIDIsValid?delegateID=...` -> `/api/checkDelegateIDIsValid?delegateId=...`
- Response DTO field changed:
  - `userID` -> `userId`
- Assignment/log usage updated to `response.userId`.

### Verification run

- `cd frontend/www && npm run build` passed.
- `cd frontend/www_vendor && npm run build` passed.
- `dotnet` CLI was not available in this environment, so Unity compile validation could not be executed here.

### Contract rule reinforced

Frontend and Unity API payload/query keys MUST use camelCase wire names:
- `userId`
- `vendorId`
- `delegateId`
