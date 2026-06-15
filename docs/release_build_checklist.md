# Web Release Build Checklist

## Export command

```sh
godot --headless --export-release "Web" builds/web/index.html
```

Output files produced in `builds/web/`:
- `index.html`
- `index.wasm`
- `index.pck`
- `index.js`
- `index.audio.js` / `index.worker.js` (if thread_support is enabled — currently disabled)

## Local test server

```sh
cd builds/web
python -m http.server 8080
```

Open: `http://localhost:8080`

> Note: the game must be served over HTTP (not `file://`) for IndexedDB save and Wasm to work.

## Layout targets

| Platform | Viewport | How set |
|---|---|---|
| Android / editor default | 720×1600 (9:20) | `project.godot` default |
| Web / Yandex Games | 720×1280 (9:16) | `window/size/viewport_height.web=1280` feature override |

Stretch mode is `canvas_items` for both. No runtime viewport code involved.

## Manual validation checklist

- [ ] No critical errors in browser console on startup
- [ ] Game scene loads and renders correctly
- [ ] Web build uses 720×1280 layout (9:16 — confirm by checking canvas size in browser DevTools)
- [ ] Android/editor build uses 720×1600 layout (unchanged)
- [ ] Touch / scroll works on mobile (test via local network IP)
- [ ] Music starts after first user interaction (canvas click)
- [ ] Music starts from a random valid track and continues in shuffled order
- [ ] Sound effects play on button clicks
- [ ] Sound/Music toggles persist after browser reload
- [ ] Game save persists after browser reload (check gold, level, upgrades)
- [ ] Rewarded ad button: fails gracefully locally (no reward granted, error logged)
- [ ] Rewarded ads call GameplayAPI.stop on open and GameplayAPI.start on close/error
- [ ] Shop purchase: fails gracefully locally (no purchase granted, error logged)
- [ ] Offline reward dialog appears and claims correctly
- [ ] Prestige works and save is written
- [ ] Reset Progress works and save is written
- [ ] Localization generated fallback is fresh after CSV changes
- [ ] SDK readiness is checked before ads, payments, language, and cloud save calls
- [ ] F12 does NOT activate debug visual test mode (release build check)
- [ ] F5–F11 debug keys do NOT respond (release build check)
- [ ] Browser console shows "Yandex SDK is not available" — expected locally
- [ ] No `push_error` spam in console

## Yandex Games upload checklist

- [ ] Export as release build (not debug)
- [ ] All files from `builds/web/` uploaded to Yandex Games dashboard
- [ ] Game tested inside Yandex Games iframe (SDK available there)
- [ ] `YandexBridge: Yandex SDK is ready` printed in console on Yandex
- [ ] `LoadingAPI.ready()` called after scene loads
- [ ] Rewarded ad works end-to-end on Yandex
- [ ] Rewarded ads call GameplayAPI.stop/start around ad display
- [ ] Fullscreen ads call GameplayAPI.stop/start around ad display
- [ ] Payments work end-to-end on Yandex (use test catalog)
- [ ] Unprocessed purchases are checked through `payments.getPurchases()`
- [ ] Unprocessed purchases are granted once, saved locally, cloud-flush requested, then consumed
- [ ] Save/load works across sessions on Yandex

## Notes

- `thread_support=false` is correct for Yandex Games (no SharedArrayBuffer required).
- Yandex SDK is loaded via `html/head_include` in `export_presets.cfg` — the `/sdk.js` path is resolved by Yandex Games hosting.
- Locally, `window.ysdk` stays null and all SDK calls fail safely.
- Debug ad/payment simulation only runs when `BuildConfig.is_debug_features_enabled()` is true; never in release.
- `window.ysdkReady` is set only after async SDK init completes; bridge calls require ready `window.ysdk`.
