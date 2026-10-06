# Notes — wave 2 R4 toolkit census (2026-10-06)

**Status:** done. ⚑ wave 2 (2026-10-06).
**Read:** census groups H + B, 316/316 rows, 43,140 B; context from the main dump (registrars,
`InitCustomDefs`, `AddAppearance`, `TranslateKey`, draw helpers) and `Cythera.rsrc` WIND/DLOG/CNTL.
**Files:** NEW `ui-toolkit.md` (203 lines); this file.
**Findings:** CDEF 1000 = push/check/radio, 1001 = scroll bar/progress bar, 1002 = edit-number/number;
WDEF 1000 border, 1001 pix frame, 1002 drawer, 1003 thin border; LDEF 128 → TListBox; MDEF 128 draws
nothing. All control and frame art comes from game tiles 0x19C–0x1AF. Per-window frame table from the
WIND resources. Appearance vs System 7 is chosen from `Gestalt('appr')` bit 0, and only the
Preferences window uses it. Quirks (HIGH, disasm): list-box Down/Right past the end clears the
selection and reveals the old cell; a dialog title's last key character never matches.
**Game-rule content:** none. Only cross-refs: Map-window 64-px grow ↔ odd tile count (engine-classes
§5 / ui-play); TSpellFX map → magic.md (LOW).
**Items closed:** none (census predicted none).
**Doubts:** MDEF 128 user not found; pix ids 0/2 of the Text/Spellbook frames not resolved to art;
TWindow layer numbers (0/1/3) and app prefs +0x65/+0x67/+0x68 meanings are MED (R3 owns prefs).

**Proposed INDEX lines**
- `ui-toolkit.md` — custom CDEF/WDEF/LDEF/MDEF ids and art tiles, per-window frame table, TWindow
  layers/drag/dock, dialog key map, TListBox keys, Appearance-vs-System-7 adapters, std containers
  (wave 2, R4).
- INDEX resource census line: CDEF 1000–1002 / WDEF 1000–1003 are JMP stubs patched by
  `InitCustomDefs @ 100a8438` (ui-toolkit.md §1).
