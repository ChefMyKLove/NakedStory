# We're Naked! — Interactivity & Animation Design
**Date:** 2026-05-07  
**Author:** ChefMyKLove  
**Approach:** Option A (vanilla) + simplex-noise caveat if dust swirl still reads "puffy"

---

## 1. Cover Dust Animation

**Goal:** Animated swirling dust visible over the cover image on load.

**Implementation:**
- Dedicated `coverDust` canvas layer (separate from main `#dust-canvas`)
- 200–300 fine individual particles with curl paths (layered sine approximation)
- Starts immediately on page load, auto-fades if user navigates away from cover
- Particle color: warm sepia tones matching cover palette
- Blend mode: `lighter` or `screen` to feel atmospheric, not opaque

**Success:** The cover feels alive. Dust swirls over the photo without obscuring it.

---

## 2. Page Flip Refinement ("Licked Finger")

**Goal:** The flip feels organic — resistance at the start, fast through the middle, soft landing.

**Implementation:**
- Tweak `cubic-bezier` to ~`(0.25, 0.0, 0.15, 1.0)` — slow lift, fast arc, soft land
- Add a growing `box-shadow` on the flipping leaf during animation (page lift illusion)
- Add a faint `linear-gradient` highlight sweep across the face during mid-flip (light catching page)
- Shadow on the static left page increases during flip (depth illusion) then fades

**Success:** Turning a page feels tactile, not like a CSS demo.

---

## 3. WE'RE NAKED! Shout Pages — Ornamental Pop

**Goal:** Literary, warm impact. The text feels like it's bursting from the book itself.

**Implementation:**
- SVG radiating ink lines (8–12 spokes) that animate outward from the text on page entry
- A decorative double-rule above/below that "draws itself" via `stroke-dashoffset` animation
- Lines animate with staggered delay, spring-like overshoot on `scale`
- Color: warm ink (`#1c1510`) with a brief gold (`#c8a96a`) flash at peak

**Success:** Landing on WE'RE NAKED! feels like a small celebration.

---

## 4. SUCH Morning Page — Particle Chaos Per Word

**Goal:** Each word's arrival is a micro-event. Pure joy-burst energy.

**Implementation:**
- Small canvas overlay on the shout page
- When each word animates in, emit 15–25 tiny particles (2–4px) in a radial burst
- Particles scatter outward, fade in ~300ms
- Particle colors: warm sepia + occasional gold fleck
- Works alongside existing `shout2-relay` word-by-word CSS animation

**Success:** The sequence feels kinetic and alive, like the words are excited to exist.

---

## 5. Dust Texture — Swirl Not Puff

**Goal:** The dust reads as swirling, not billowing. Fine movement, not cloudlike.

**Implementation:**
- Keep existing `CloudMass` system as soft background layer (reduce opacity ~30%)
- Add 250 individual `DustParticle` objects on top:
  - Each has position, velocity, and a curl angle derived from layered `sin/cos`
  - Rendered as 1–3px dots or short line segments (elongated in direction of travel)
  - Wrap at screen edges
- If layered-sine curl still reads "puffy": drop in `simplex-noise` CDN (2KB) for true Perlin curl

**Success:** Dust feels like it's genuinely swirling through the air.

---

## 6. Text Layout — Vertical Centering on Spreads

**Goal:** Story text sits in the optical center of each page half, not piled at the top.

**Implementation:**
- `.page-surface` already uses `display:flex; flex-direction:column`
- Add `justify-content: center` to `.page-surface` for spread pages
- Keep running head at top (absolute position or separate from flow)
- Keep page number at bottom (already absolute)
- Story text block gets `max-height` with `overflow:hidden` to prevent bleed

**Success:** Opening any spread page feels like opening a beautifully typeset book.

---

## Out of Scope (Tonight)

- Sound design / page turn audio
- GSAP dependency
- Mobile interactivity improvements
- Accessibility / ARIA enhancements
