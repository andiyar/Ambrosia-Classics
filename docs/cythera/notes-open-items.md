# Notes — open-items reader, 2026-10-03

Output: `open-items-2026-10-03.md` (INDEX NOT RESOLVED items 1, 4–10, 12, 16, 18, 19).
Result: 9 resolved, 3 partial, 0 wholly open.

How: decompile reading plus a scratch PPC decoder for bodies Ghidra dropped (TStream
format writer/chunks, `TMapWindow::KeyRoutine`, `TViewer::AddSound`). r2 = 0x100D5280 lets
every direct-addressed global be enumerated; `FUN_100c50e8` is `__ptr_glue`, so the
"unnamed glue" calls are virtuals, resolved by reading vtables out of the unpacked data
section. Function names for undecompiled bodies come from PEF traceback tables.

For the fix pass:
- script-vm.md §2.1: the class-0x28 row's segments 0x1500–0x1502 are zone ids 0x100–0x102
  of class 0x20; class 0x48 = monster species (0xF008).
- data-format.md: header +0x40/+0x42/+0x48/+0x20; 'B' frames 1–7; kind 0x80 = hidden;
  prop +0xE = elevation; 0xF008/0xF00D/0xF00F/0xF011/0xF012 rows; tile-flag bits 0–1 and
  0x10000 = light emitter; CharEntry rows; save-stream chunk encoding; `'asnd'` layout.
- script-builtins.md §4: every glue callee named; FC = auto-map flag.

Still open: prop kind 0x11, 0xF005/0xF007, `PORT`, `Render` layer order, global 0x0E's
meaning, who sets pref bit 0x100D3E23.
