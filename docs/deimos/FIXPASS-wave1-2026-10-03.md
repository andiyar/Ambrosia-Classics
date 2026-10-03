# Deimos Rising RE bank — wave 1 fix pass, 2026-10-03

All 11 review findings are applied in place, each marked `⚑ corrected (review wave 1, 2026-10-03)`. The
important one changes how turrets work: a player's shot that touches a turret hurts the turret, not the
tank or gun underneath; only ramming passes damage down. The boss file now lists how many bombs each
turret takes on its own. The four functions that two files described differently were settled from the
disassembly: a rotation gate, a find-and-switch-state helper, the REVERSE debug command, and the unit
module's start-up. 68 role labels that rested on decompiler reading alone were lowered from HIGH to MED,
so the table now counts 240 HIGH, 256 MED, 14 LOW. Two small open questions were closed, and the
random-number section now lists the consumers nobody has read yet.
