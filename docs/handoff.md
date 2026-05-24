# We're Naked! — Agent Handoff Document

**Project:** Interactive HTML literary book — *We're Naked! A Rapture in Three Acts* by ChefMyKLove  
**Single working file:** `C:\Users\micha\Desktop\wereNaked_story\index.html` (~4,750 lines)  
**All other files:** MP3 audio assets + `cover.jpg` + `img_0288.jpg` — all in the root directory alongside `index.html`. No build step. Opened directly in a browser via `file://`.

---

## Architecture Overview

The file is self-contained. Two structural halves:

### 1. HTML + CSS (lines 1–1413)
- CSS custom properties on `:root` for colours and timing
- Book engine styles: `.page-frame`, `.page-surface`, `.story-text`, `.cover-page`, `.back-cover-page`
- Mobile-specific `@media (max-width: 800px)` block — makes `.page-surface` scrollable and `.story-text` non-flex so it can grow past container
- `#mobile-fallback` (old scroll fallback, currently `display:none` — not used)
- `#mob-splash` (mobile tap-to-begin overlay, shown on `≤800px`)
- `#mob-ctrl-tray` (mobile circular button tray, bottom-right)
- `#info-modal` (tutorial/disclaimer overlay)

### 2. JavaScript — Two IIFEs (lines ~3447–4363)

**IIFE 1 — Main book engine + HTML audio (lines ~3447–3413)**  
Handles: page rendering, navigation, cover cloud animation, dust particle system, fireworks, mix panel, HTML `<audio>` ambient layers.  
Key globals it exposes on `window`:
- `window.goToPage(idx)` — navigate without resetting audio
- `window.toggleMixPanel()` — open/close mix panel
- `window.stopOutdoorAmbient(fadeMs)` — stop city/birds with optional fade. Pass `0` for instant.
- `window.startOutdoorAmbient()` — start city/birds looping (uses `el.loop = true`, NOT clone-chain)
- `window.duckOutdoorAmbient()` / `window.unduckOutdoorAmbient()` — smooth volume duck via `fadeVol()`
- `window.revealAudTgl` — show the audio toggle button
- `window._giggleCheck` — returns `audOn && !CH_PAUSED.sfx`
- `window._giggleVol` — returns `VOL.sfx` (default 0.50)
- `window.updateExtBtns()` — refresh all 4 extended giggle button states
- `window.onAudioPageChange(pageId)` — called on every page turn
- `window.onFirstPageTurn()` — fires once on first turn

**IIFE 2 — Giggle system / Web Audio API (lines ~3941–4363)**  
Handles: single giggle variants (16 short ~2s clips), 4 extended ~30s looping modes.  
Key globals:
- `window.playGiggle()` — stops outdoor sounds + plays one of 16 shuffle-deck variants
- `window.toggleGiggleExt(mode)` — toggle extended mode 1/2/3/4 on/off

**CRITICAL SCOPE RULE:** These two IIFEs cannot share private variables. Any function one needs from the other MUST be exposed on `window`. The bug where giggle couldn't stop outdoor sounds was exactly this — `stopOutdoorAmbient` wasn't on `window`.

---

## Audio System

### HTML `<audio>` elements (IIFE 1)
Defined inside `#audio-engine` div. All ambient/music layers use native `<audio>` elements.

| Element ID | Role |
|---|---|
| `a-music` | Background music (loops) |
| `a-atmos` | Dust atmosphere (loops) |
| `a-sfx-city` | City traffic ambient (loops, `loop=true` set at runtime) |
| `a-sfx-birds` | Birds ambient (loops, `loop=true` set at runtime) |
| `a-sfx-door` | Door open/close (one-shot, plays on door-page) |
| `a-sfx-fan` | Fan sound (loops while fan is on) |
| `a-sfx-cig` | Cigarette crackle |
| Various `a-fw-*` | Firework audio elements |

**Mobile loop fix (important):** `startOutdoorAmbient()` uses `el.loop = true` on the original `<audio>` element + `fIn()` to fade in. Earlier clone-based crossfade was removed because iOS blocks `el.play()` on cloneNode elements in timer callbacks (not a user gesture).

### Volume helpers
```js
fIn(el, vol, ms)    // fades in — ALWAYS resets el.volume = 0 first (gotcha!)
fOut(el, ms, cb)    // fades to 0 then pauses
fadeVol(el, target, ms)  // interpolates from CURRENT volume to target (no reset)
```
Use `fadeVol` when you don't want a hard volume reset (e.g. ducking while already playing).

### Web Audio API (IIFE 2)
**Audio loading:** Uses `XMLHttpRequest` with `responseType = 'arraybuffer'` (NOT `fetch()`). `fetch()` is blocked on `file://` protocol in Chrome — XHR works. First giggle/extended press loads all buffers; subsequent presses use cached `loadProm`.

**All SRC keys:**
```
m1, m2         — male laughs (universfield)
f1, f2, f3     — female laughs/giggles (freesound)
g3, g4, g9, g10 — giggles (freesound)
sg             — small giggle
lf             — laugh (freesound-105488)
cl             — cheerful laugh (koiroylers)
sl             — silly laugh man (oceaneyes91)
sw             — sweet woman laugh (u_i2qs5hn9ii)
d1, d2, d3     — door close/open sounds (dragon-studio)
w1, w2         — cinematic whooshes (chrysalyn, studiokolomna)
qw             — quick whoosh (dragon-studio-405448)
qs             — quick swooshing (freesound-80898)
```

**`pb(key, when, opt, dest)`** — plays a buffer node. Returns silently if `bufs[key]` is undefined. Options: `vol`, `rate`, `pan`, `delay`, `fb` (feedback), `dur`, `off`.

---

## Extended Giggle Modes

Four modes, all ~31s loop duration:

| ID | Name | Character |
|---|---|---|
| 1 | `↻ dreamy` | Sparse, long echo tails, 15 events |
| 2 | `✦ chaos` | Dense overlapping, 4 whooshes, 5 doors |
| 3 | `✶ rapture` | Narrative arc — sparse whispers → peak climax → coda |
| 4 | `⁕ rando` | Fully procedural — 16–28 events, all parameters re-rolled every loop cycle |

**Rando effect modes (per event):**
- 28% → reverb wash: delay 15–65ms + high feedback 0.72–0.87
- 38% → normal echo: delay 120–380ms
- 16% → long trailing echo: delay 400–780ms
- 18% → dry (no effect)
- Pitch: 10% deep/slow (0.38–0.58×), 8% chipmunk (1.55–2.2×), rest normal range

State arrays: `extState[4]`, `extMG[4]`, `extTimer[4]`, `EXT_DUR[4] = [31500, 31500, 32000, 31000]`

---

## Mix Panel

HTML: `#mix-panel` div (after the main script block, ~line 3416).  
Toggle: `window.toggleMixPanel()` exposed by IIFE 1.  
Close-on-outside-click listener: `document.addEventListener('click', ...)` in IIFE 1 checks `!mixPanel.contains(e.target) && e.target !== mixBtn`.

**Known gotcha (now fixed):** Mobile tray button `#mct-mix` was missing `e.stopPropagation()`, so the same click that opened the panel also bubbled to the document listener and immediately closed it. This is now fixed at line ~4651.

---

## Mobile Tray (`#mob-ctrl-tray`)

Located at bottom-right on `≤800px`. Contains:
- `#mob-ctrl-handle` — circular toggle button  
- `#mob-ctrl-drawer` — expands to show circular proxy buttons

Proxy buttons and what they call:
| Button ID | Calls |
|---|---|
| `mct-sound` | `#aud-toggle` click |
| `mct-mix` | `window.toggleMixPanel()` + `e.stopPropagation()` |
| `mct-fw` | `#replay-fireworks` click (hidden unless visible class on real button) |
| `mct-dust-tgl` | `#dust-toggle` click |
| `mct-dust-rep` | `#replay-dust` click |
| `mct-info` | Opens `#info-modal` |

Auto-close timer: 4.5s. `closeTray()` closes immediately.

---

## Page Navigation

**Book engine** is in the first IIFE. Pages defined in an array of objects (`AP()`).  
Key state: `currentPage` (integer index), `isAnimating` (bool, prevents double-flip).

```js
window.goToPage(idx)   // navigate to page index, preserves audio state
goNext()               // advance one page (with flip animation)
goPrev()               // go back one page
```

Keyboard: ArrowRight/Down/Space → next. ArrowLeft/Up → prev.  
Click: nav arrows `#nav-next`, `#nav-prev`.  
No `wheel` event handler currently — see Pending Issues below.

---

## Key Page IDs (for audio hooks)

`window.onAudioPageChange(pageId)` fires on every turn. Key page IDs that trigger audio:
- `'cover'` — cover page, cloud animation starts, outdoor ambient NOT playing yet
- `'act1-door'` (approx) — door page, `startOutdoorAmbient()` fires
- `'act1-giggle'` — giggle page, extended mode buttons visible
- `'act3-fan'` — fan page, `duckOutdoorAmbient()` on fan-on, `unduckOutdoorAmbient()` on fan-off
- `'back-cover'` — back cover, has "↺ read again" button → `window.goToPage(0)`

---

## Session History — What Was Fixed

### This session (most recent)
1. **Giggle audio loading** — replaced `fetch()` with XHR (`responseType='arraybuffer'`). Chrome blocks `fetch()` on `file://`; XHR works. Buffers now load on first giggle press.
2. **Mix panel not opening on mobile** — added `e.stopPropagation()` to `#mct-mix` click handler (line ~4651). Without it, click bubbled to document listener which immediately closed the panel.
3. **4th extended giggle mode "⁕ rando"** — fully procedural, re-rolls all parameters (density 16–28, timing, pan, pitch, reverb wash/echo/long echo/dry) every 31s loop cycle. Uses all 21 SRC keys including 4 new laugh files and 2 new whoosh files.

### Prior sessions
4. **Outdoor ambient looping on mobile** — switched from clone-based crossfade to `el.loop = true` on original elements. Clone-based approach was blocked by iOS's audio gesture policy.
5. **`stopOutdoorAmbient(0)` was using 1400ms fade** — `fadeMs || 1400` treated `0` as falsy. Fixed: `typeof fadeMs === 'number' ? fadeMs : 1400`.
6. **`stopOutdoorAmbient` not accessible from giggle IIFE** — exposed as `window.stopOutdoorAmbient` at end of IIFE 1.
7. **Fan click causing outdoor sounds to dip to 0** — `duckOutdoorAmbient()` was calling `fIn()` which resets volume to 0. Fixed with new `fadeVol()` helper that interpolates from current volume.
8. **Mobile text truncation** — `.story-text` changed from `flex: 1` to `flex: none; height: auto` in mobile CSS, making `.page-surface` actually scrollable. Nav arrows shrunk to 26×56px, text padding widened to 34px.
9. **Tutorial/disclaimer modal** (`#info-modal`) — full interactive feature guide, PC disclaimer, opened via `?` button in mobile tray and fixed bottom-left button on desktop.
10. **"↺ read again" button** — on back-cover page, calls `window.goToPage(0)`.

---

## Pending Issues

### 1. Landing page scroll (NOT fixed)
**Symptom:** User expects scrolling (mouse wheel) on the cover page to advance to page 1. No `wheel` event listener exists anywhere in the book engine. Only keyboard arrows and click on nav arrows work.

**Fix to implement:**
```js
// Add to the book engine IIFE after the keyboard listener (line ~3379)
let wheelLocked = false;
document.addEventListener('wheel', function(e) {
  if (wheelLocked) return;
  if (e.deltaY > 30) { goNext(); wheelLocked = true; setTimeout(() => wheelLocked = false, 900); }
  if (e.deltaY < -30) { goPrev(); wheelLocked = true; setTimeout(() => wheelLocked = false, 900); }
}, { passive: true });
```
The `wheelLocked` throttle is essential — trackpad users generate dozens of wheel events per scroll gesture.

### 2. Mobile fallback "scroll to begin" dead text
`#mob-cover` inside `#mobile-fallback` shows "scroll to begin" but `#mobile-fallback` is `display:none` — it's never shown. On mobile, the book engine is the experience (`#mob-splash` tap-to-begin is used instead). Either remove the fallback entirely or confirm it's intentionally kept as dead code.

### 3. Giggle sound on first press — cold load delay
On first giggle press, XHR loads 21 files before playing. On a slow system there could be a noticeable delay between stopping outdoor sounds and hearing the giggle. Consider pre-loading buffers on first audio enable (`onFirstPageTurn`) rather than lazily on first giggle press.

---

## Common Gotchas

| Issue | Root cause | Fix |
|---|---|---|
| `fIn(el, ...)` resets volume to 0 | Intentional — it's a "start from silence" fade. Use `fadeVol()` if el is already playing | Use `fadeVol` for duck/unduck |
| iOS audio won't loop | `cloneNode(false).play()` in timer = not a user gesture | Use `el.loop = true` on original element |
| `fetch()` fails on `file://` | Chrome security policy | Use XHR `responseType='arraybuffer'` |
| Panel opens then immediately closes | Click bubbles to document listener | `e.stopPropagation()` in opener |
| `stopOutdoorAmbient(0)` uses 1400ms | `0 || 1400` is falsy | `typeof x === 'number' ? x : 1400` |
| Mobile text not scrollable | `flex:1` on story-text caps its layout size | `flex:none; height:auto` |
| Web Audio not playing | AudioContext suspended | Call `AC.resume()` inside user gesture handler |

---

## File Map (audio assets)

All MP3s live in the same directory as `index.html`. No subdirectories.  
Ambient/SFX (used by HTML audio elements): `patolenin-sounds-of-cars...`, `freesound_community-birds-chirping-98527.mp3`, `freesound_community-bird-chirps-short-96913.mp3`, `dragon-studio-fan-blowing-359881.mp3`, `dragon-studio-open-and-closed-door-405452.mp3`, `freesound_community-open-sliding-door-105746.mp3`, `freesound_community-cigarette-*.mp3`, firework files.  
Giggle buffers (Web Audio API): all 21 keys in `SRC` object (lines ~3950–3972).
