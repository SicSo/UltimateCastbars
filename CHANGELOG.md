## Unreleased

### Fixed
- Channel casts that were secrets caused issues with cancelled overlays

---


## Version 0.9.3 - [26-02-2026]

### Fixed
- Removed debug code 

---


## Version 0.9.2 - [26-02-2026]

### Added
- A control variable to modify the cancelled channel window to account for an "error" threshold (default 100ms or 0.1s)

### Changed
- Updated LibSharedMedia-3.0 to current version

### Fixed
- Update events for channel/empower spells were not behaving as intended
- Hide changelog button on non UCB frames
- Show/Hide preview was not working correctly in between castbar types of tabs
- Copy profile was copying generated keys that were not in schema 

---


## Version 0.9.1 - [23-02-2026]

- Support for automatic Curse and Wago releases

---


## Version 0.9.0 - [23-02-2026]

### Added
- Castbars for **player, target, focus** (supports **casts, channels, empowered**).
- Preview simulator that uses the real cast pipeline:
  - Preview **cast / channel / empowered**
  - Looping previews
  - Select preview spells from detected spell lists
  - Configure duration, empower stages, and “not interruptible”
  - Drag the preview bar to reposition and write offsets back
- Copy settings between bars (per section/category).
- Import/Export profiles + profile management (copy/reset/delete; optional dual-spec support).

---

- Frame search using a frame picker
- Anchoring with `anchorFrom` / `anchorTo` pairing + X/Y offsets
- Late-loading frame resolution (retry + delay/interval)
- Size options:
  - Manual width/height
  - Frame sync (sync width and/or height + offsets)
  - Min width/height
  - Border-aware sizing (include border thickness)
- Spell icon:
  - Show/hide, anchor around the bar, offsets
  - Sync icon size to bar height or set explicit width/height

---

- Text options with a **tag/token system** and custom text
- Text items can be added, deleted, or edited
- Text items can be positioned and styled per item or globally per bar
- Text items can be conditional based on cast/effect state
- Tags support types: **Cast / Interrupted / Cancelled**, with show rules by cast type/state
- Performance-aware updates for text: **Static / Semi-Dynamic / Dynamic**
- Text list includes useful defaults for convenience

---

- Styling for textures (LibSharedMedia) for fill, background, and border
- Styling for colours for fill, background, and border:
  - **Class colour / Ombre / Custom colour** (optional gradient start/end)
  - Target/Focus can use separate enemy NPC colours
- Borders:
  - Thickness + per-side offsets
  - Bar + icon border handling (synced/independent options)
  - Dynamic negative border offsets based on border thickness

---

- Uninterruptible visuals for uninterruptible casts:
  - Hide bar or change opacity (optional icon inclusion)
  - Custom fill/overlay/background/border for uninterruptible state
- Kick/Interrupt cooldown awareness:
  - Hide bar until kick is ready, or opacity changes while on cooldown
  - Optional dynamic alpha updates during the cast
  - Kick-ready tick marker
  - “Until kick” fill region with optional overlay/background

---

- Visibility options: Strata and Frame Level for the bar

---

- Other features:
  - Channeling: global per-bar option to show ticks (plus global tick visuals)
  - Spell Queue Window overlay for player castbar (+ read/write `SpellQueueWindow` CVAR, optional custom ms)
  - Invert and/or mirror the castbar fill (per cast type)
  - Interrupted/Cancelled overlays and effects (per effect type + cast type, textures/colours + duration)
  - Kicked/Cancelled effects with custom options for text/colours and per spell type

---

- Class specific:
  - Channel ticks per spell per class for player bar (spec-aware UI)
  - Channel ticks per class for target/focus bar (class defaults + spec placeholders)
  - Blacklist/Whitelist spell filter for player bar (add by spell picker or spell ID)
  - Evoker:
    - Dynamic Disintegrate tick logic (Devastation) + fallback to static ticks if disabled
    - Empower visuals: stage tick marks/segments, per-stage tick + colour control, optional textures
    - Manual tick placement (percent-based) + reset
    - Custom empowered effects for ticks/background/fill (all)
    - Custom tick positions (target, focus)

---

- Default Blizzard castbar:
  - Show/hide default castbar (debug/compat)
  - Resize, reposition, and scale default castbar
  - Optional static bar for comparison/testing
  - Baseline capture + “late restore” to reduce drift
  - Re-apply hide/show if Blizzard attempts to show frames again
  - Debug mode that disables all other addons and restores them later
