# notes-w2-dialogue — reader R2, wave 2 (2026-10-06)

**Status:** done. Read 199/199 group E+F bodies whole (71 E incl. 3 `TScriptPickItemDrawer`, 128 F) plus
main-dump context (CreateSysObj, Display*, ctors, dispatch, PlaySound, mixer helpers).

**Files:** NEW `dialogue-ui.md` (353), NEW `scripted-windows.md` (374); appended `script-builtins.md`
(187 → 263: §2.1 names, D4), `script-library.md` (519 → 568: §9.1 N3, §0/§12 marks).

**Closed:** item **19** (D4 = `cbPlaySoundSync`, busy-waits on the mixer voice; MED only for end-of-sample
removal). Review note **N3** (scan reproduced, shown complete, every r4 a literal → HIGH; sel 1/23 named;
3012/3013/303D/303E unreached HIGH). dialogue.md §15 items 2, 4 (conversation side), 8 (mygetnum
callers), format half of 1.
**Item 23 native side:** TWMusicBox → sel 10 to the instrument prop with `(history<<4|note)&0x0FFFFFFF`;
1099/109A use_on → signals 129/131. TWPixButton f39 handlers (1175) → signals 132–134. No other new
signal sender. Join with R5.

**Doubts:** 0x110/0x113 key codes; WDEF refCon use; renumber timing; lyre via UseOnCommand (MED).

**Proposed INDEX lines:**
- `dialogue-ui.md` — conversation window, TInteraction modes (chips, MORE, how-many, pick list + row
  format language, modal), journal buttons.
- `scripted-windows.md` — sysnew class map, window/widget ids, fields 0x37–0x41, handlers (sel −1),
  shortcuts, drag/drop sel 23, stream tags/registrars, music box → signals.
- NOT RESOLVED 19 → closed (script-builtins §4). Item 23 → native senders in scripted-windows §7.
- Review note N3 → lifted (script-library §9.1).
