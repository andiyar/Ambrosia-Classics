# notes — wave 2 reader R1 "play" (2026-10-06)

**Status:** done. Read 105/105 bodies of census groups D + G (27,040 B; list in ui-play.md §0),
whole, plus main-dump context (PostInit, RecalcWieldList, ChangePane, DropCommand, DoMissile,
Render pass loop, RebuildList/RebuildInventory, IsStraightRel).

**Files:** NEW `ui-play.md` (516 lines); `magic.md` 398 → 466 (§11 FX); `combat.md` 585 → 616
(§17 cross-reference).

**Rules found:** equip slots by property 0x26 (two-hander = both hands, either hand takes shield or
one-hander, max two rings — third refused with the two-hands message); strategy popup/radios write
CharEntry +0x1E; non-party windows collapse unless adjacent, close when not visible; F-keys act for
the leader, portrait menus for that member; throws need only a visible straight line; status
command buttons fire without testing TrackControl; `cmpprops` frame test duplicated.

**Items:** 14 — native UI writer of +0x1E stated (v=1 edit, else +0x1E = v+0xAD), ties
schedules §2.3 (cross-ref; R3 closes). 16 — narrowed: in-flight FX shown at the start of
`Render` pass 5 of 0–5; no clock wait in FX bodies or the map AnimThread. Layer meaning still open.

**Doubts:** status-button refcons unfound; `TInventoryList+0x10`; GetGesture `(mods & 3)`;
CanSearch tile-bit names; RenderMissiles' `cdc40[leader]` purpose.

## Proposed INDEX lines
- `ui-play.md` — play windows: character (panes, equip slots, CanDrop rules, tactics/+0x1E),
  status (F-keys, portraits, command buttons, give-by-drop), map (cell maths, drop/throw, resize,
  keyboard target), containers (close at distance), journal, to-do; gesture timing, search reach.
  ⚑ wave 2 (2026-10-06)
- `magic.md` §11 — missile/FX classes, hit table, RenderMissiles call site (item 16 narrowed).
- `combat.md` §17 — equip/reach/throw cross-reference into ui-play.md.
- NOT RESOLVED 16: narrowed — FX drawn at the top of `Render__7TViewer` pass 5 (passes 0–5, after
  the tile copies); per-pass meaning open (magic.md §11.3).
- NOT RESOLVED 14: UI writer of +0x1E documented (ui-play.md §6.1).
