# C7.2.4 — Guest Paid Shop Lock UX Validation

## Overview

- The `donation_entry` shop card (`gem_purchase_entry`) now visibly reflects
  whether paid gem purchases are available: normal "Open" state for an
  Android account session or Web/Yandex, and a muted "account required" state
  for Android Guest.
- `rewarded_ad` and all other product types are completely unaffected —
  rewarded ads remain available and normal in Guest mode.
- Tapping the locked donation entry now shows a short status message in the
  shop sheet before opening the AuthGate overlay (previously it silently
  opened the overlay with no in-sheet feedback).
- The technical guards from C7.1 (`_is_paid_shop_available()` checks in
  `_on_shop_product_purchase_requested` and `_on_gem_product_purchase_requested`)
  are unchanged — this patch only adds visual/status feedback around them.

---

## What Changed

- `scenes/ui/ShopPanel.gd`
  - New `var paid_shop_available: bool = true` and
    `set_paid_shop_available(is_available: bool)` — only triggers a refresh
    when the value actually changes; owned by ShopPanel for rendering only
    (ClickerScreen owns the account/session decision).
  - `_update_product_row()`: for `product_type == "donation_entry"` only, when
    `paid_shop_available` is false, the button label switches to
    `shop.paid_guest_locked_action` ("Sign in / Register") and the description
    switches to `shop.paid_guest_locked_short` ("Account required"); the
    button/label get a muted amber tint distinct from the normal
    enabled/disabled dimming. `rewarded_ad` and all other branches are
    untouched.
- `scenes/ui/ShopSheet.gd`
  - New `set_paid_shop_available(is_available)` delegating to `shop_panel`.
  - New small `_locked_status_label` (created at runtime in `_ready()`, same
    pattern as other dynamically-built UI in this codebase) and
    `show_status(text)` to display a short transient message; cleared
    whenever the sheet is (re)opened via `show_sheet()`.
- `scenes/game/ClickerScreen.gd`
  - `_on_shop_product_purchase_requested()`: when the donation entry is
    tapped while paid shop is unavailable, calls
    `shop_sheet.show_status(tr_key("shop.paid_guest_locked_message"))` before
    opening the AuthGate overlay (same overlay call as before — unchanged).
  - `_on_gem_product_purchase_requested()`: the pre-existing
    `if not _is_paid_shop_available(): return` guard is preserved; now also
    shows the same status message if the shop sheet happens to be visible
    when this path is reached.
  - `_update_shop_paid_availability()`: now also calls
    `shop_sheet.set_paid_shop_available(paid_available)` before the existing
    `gem_purchase_dialog` hide-if-visible check and `_update_ui()` call.
  - `_ready()`: added one line right before the first `_update_ui()` call to
    sync `shop_sheet.set_paid_shop_available(_is_paid_shop_available())` at
    startup, so a cold-started Android Guest session shows the locked donation
    entry immediately, not only after the next `backend_auth_changed` event.
- `localization/game_text.csv` / `scripts/ui/LocalizationData.gd`
  - Added `shop.paid_guest_locked_short` ("Account required" /
    "Требуется аккаунт") for the card description.
  - Reused the existing (previously unwired) `shop.paid_guest_locked_action`
    and `shop.paid_guest_locked_message` keys from C7.1 for the button label
    and tap-time status message, respectively — no near-duplicate keys added.

## What Did NOT Change

- Payment/RuStore purchase flow, `GemPurchaseConfig` prices/products — untouched.
- Rewarded ads and their reward logic — untouched; Guest can still tap and
  receive rewarded-ad gems normally.
- Backend Cloud Functions, backend API paths, cloud-save logic — untouched.
- Guest → Login / Guest → Register logic (C7.1) — untouched; both flows still
  call `_update_shop_paid_availability()` on success, which now also updates
  the shop's visual lock state.
- `product_purchase_requested` signal and other `ShopSheet`/`ShopPanel`
  signals — unchanged names/signatures.
- Reset Progress — remains removed (C7.2.1); not reintroduced.
- Web/Yandex behavior — `_is_paid_shop_available()` still returns `true`
  unconditionally off-Android, so the shop is never shown as locked there.

---

## Checklist

- [x] `ShopPanel.set_paid_shop_available()` / `ShopSheet.set_paid_shop_available()`
      only affect `product_type == "donation_entry"` rendering.
- [x] `product_type == "rewarded_ad"` and all other product types render
      exactly as before regardless of `paid_shop_available`.
- [x] `ClickerScreen` still owns the account/session decision
      (`_is_paid_shop_available()`); `ShopSheet`/`ShopPanel` only render the
      flag they're given.
- [x] `_update_shop_paid_availability()` updates the shop UI, hides
      `GemPurchaseDialog` if it was open and paid shop just became
      unavailable, and refreshes `_update_ui()` — called after backend auth
      changes and after Guest→Register/Guest→Login success (unchanged call
      sites from C7.1).
- [x] Startup path (`_ready()`) syncs the shop lock state once before the
      first `_update_ui()`, so a cold Guest session isn't shown as unlocked
      until the next auth event.
- [x] Direct gem purchase guard (`if not _is_paid_shop_available(): return`)
      preserved in `_on_gem_product_purchase_requested()`.
- [x] No `Platform.purchase_product()` call reachable in Guest mode (guard
      returns before that line).
- [x] `GemPurchaseDialog.show_dialog()` not reachable in Guest mode (donation
      entry handler returns before that line when unavailable).
- [x] Reset Progress remains absent.
- [x] Web/Yandex `_is_paid_shop_available()` still unconditionally `true`.

---

## Manual Checklist

### Android Guest
- [ ] Open shop. Donation entry ("Buy Gems") shows muted/locked styling and
      "Account required" description; button reads "Sign in / Register".
- [ ] Rewarded ad product card looks and behaves exactly as before (normal
      styling, "Watch Ad" button).
- [ ] Tap donation entry: a short status message appears in the shop sheet,
      then the AuthGate overlay opens.
- [ ] `GemPurchaseDialog` does not appear.
- [ ] No RuStore/Platform purchase call is triggered.
- [ ] Tap the rewarded ad product: ad plays and reward is granted as before.

### Android Account
- [ ] Open shop. Donation entry shows normal styling and "Open" button text.
- [ ] Tapping it opens `GemPurchaseDialog` normally.

### Guest → Register / Guest → Login / Logout
- [ ] After Guest → Register completes, reopen (or already-open) shop shows
      donation entry unlocked without needing to close/reopen the sheet.
- [ ] After Guest → Login completes, same as above.
- [ ] After Logout, donation entry becomes locked again immediately.

### Web / Yandex
- [ ] Web build: donation entry always shows the normal "Open" state; no
      locked styling ever appears.

---

## Static / Tooling Checks

```bash
godot --headless --editor --quit
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
godot --headless --script res://scripts/tools/ValidateLocalizationDataFreshness.gd
godot --headless --script res://scripts/tools/ValidateLocalizationExport.gd
git status
git diff --stat
```

**Results (run during C7.2.4 implementation):**
- `godot --headless --editor --quit` — no errors.
- `GenerateLocalizationData.gd` — generated 459 keys (458 → 459, one new key).
- `ValidateLocalizationDataFreshness.gd` — PASS (459/459 keys, 0 errors, 0 warnings).
- `ValidateLocalizationExport.gd` — PASS (459 EN keys, 455 RU values, 0 errors).

---

## Files Changed in C7.2.4

| File | Change |
|------|--------|
| `scenes/ui/ShopPanel.gd` | Added `paid_shop_available` flag and `set_paid_shop_available()`; donation-entry-only locked visual state |
| `scenes/ui/ShopSheet.gd` | Added `set_paid_shop_available()` delegation and a small runtime-created status label/`show_status()` |
| `scenes/game/ClickerScreen.gd` | Wired shop lock status message into donation-entry tap and direct gem purchase guard; `_update_shop_paid_availability()` now updates shop UI; startup sync added |
| `localization/game_text.csv` | Added `shop.paid_guest_locked_short`; reused existing C7.1 `shop.paid_guest_locked_action`/`_message` keys |
| `scripts/ui/LocalizationData.gd` | Regenerated from CSV (459 keys) |
| `docs/validation/guest_paid_shop_lock_ux.md` | New validation doc (this file) |
| `README.md` | Added C7.2.4 section |
| `AGENTS.md` | Added Guest paid shop lock UX rules |

---

## Known Limitations

- `shop.paid_guest_locked_title` (added in C7.1) remains unused; it was
  already unwired before this patch and is out of scope to wire up or remove.
- No ScrollContainer or shop redesign was introduced; the locked donation
  entry card fits within the existing card layout unchanged.
