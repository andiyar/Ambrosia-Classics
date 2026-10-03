# Deimos Rising RE bank — wave 2 fix pass, 2026-10-03

Every review and critic finding for wave 2 was checked against the raw disassembly and applied in place,
marked `⚑ corrected (review wave 2, 2026-10-03)`. The important one: the FPS counter keeps updating
when the frame limiter is off; only the "too slow, switch on interlacing" logic stops. Two proposed
fixes did not survive the listing and are recorded instead: the high-score and film-end compares are
signed, not unsigned, and the particle draw is gated on the "draw background" argument (always 1 in a
game), not on the tick flag. New: a start-up routine rewrites the sprite draw template before the game
runs, so its clip is the 416 × 480 play area, not zero; every template value read from the data image
now carries a caution, and the full audit is new open item #56. Rule 2's distance test (within range,
inclusive), tail-append lists (#38), save-at-quit for erased scores (#55), always-on shadows and the
PLAYER AIRWEP/GROUNDWEP naming are settled; #48 narrowed; 20 stale file-level open items struck. Labels: 4
synthesis rows back to HIGH on quoted listings, 32 owning-file rows down to MED; table 397/267/15.
