# notes — R5 open items, wave 2 (2026-10-06) ⚑ wave 2 (2026-10-06)

Status: done. Read: DoExpr/DoInterpAt 0x9C (disasm), GetMonstAttrs/TGameSys::CanMove/HandleMove,
RepositionChar, DrawRoutine 'B' loop, Load/SaveLevelProps, HatchEgg/Die/LeaveLevel, scripts 0C80,
1025, 10EA, 184F, 1802, 1099, 109A, 10C1, 10E8, 1175, 1417/1419/1428; data F005/F007/F008, 0x81xx
props, PORT, clut; the hintbook (documentation).
Files: open-items-2026-10-06.md 375 (new); script-vm.md 270, quests-flags.md 458,
schedules-npcs.md 557 (appends).
Closed: 21, 24, 25, 5, 6 (no reader), 10, 22, 23 (script side). Narrowed: N2.
Doubts: the F005 colour-cycle role (MED) and F007 (LOW). The movement-bit names (MED). Whether
0C80's bits 6/7 were meant as 4/5. Where a quality-1 panpipe comes from.
Flags for other owners: wave 1 inverted the crystal-quality branch (quests-flags §5, now marked).
rules.md §3.4 has the 0x80-walk condition backwards. combat.md §16.4 needs a pointer to
open-items-2026-10-06 §2. data-format §4.3/§5 rows for kind 0x11 and F005/F007.

Proposed INDEX lines:
- 5 kind 0x11 — CLOSED: inert NPC equipment records, no reader (open-items-2026-10-06 §4) [HIGH/MED]
- 6 F005/F007 — CLOSED: data present, no reader; F005 = palette-cycle ranges, ColorCycle is a stub (§5) [HIGH/MED/LOW]
- 10 PORT — CLOSED: LZ 64×64 placeholder face + a non-image buffer, no reader (§6) [HIGH/LOW]
- 21 0x9C FFFF — CLOSED: +1 stale slot per use, reclaimed at frame end; harmless in data (§1) [HIGH]
- 22 crystal quality — CLOSED: Charax charges the distiller, the distiller sets quality 1 → saved ending; branch inverted in wave 1 (§7) [HIGH]
- 23 signals — CLOSED (script side): senders/receivers table (§8) [HIGH]
- 24 F008 byte 7 / flag bits — CLOSED: byte 7 padding; f32 1/2/4, f33 0x1000–0x8000 = movement bits; f32 16/32 unread (§2) [HIGH/MED]
- 25 egg re-arm / activity restore — CLOSED: neither exists; hourly reschedule restores (§3) [HIGH]
- N2 — NARROWED: 0C80 chooses by bits 6/7 (§9) [HIGH bytes/MED intent]
