# notes — magic bank (2026-10-03)

**Read:** all 87 page-0x1A listings; the casting and learning routines (0EA1, 0E85, 0E8A, 0EB5,
0E83, 0EAF, 0EB1, 0EB8); the defaults 301A/301F/3040/3041; the magic items; all 9 `TSpellFX`
methods; the native targeting code (`PostUse`, `NeedsTarget`, `MouseRoutine`).

**Counts:** 49 spells, 23 skills, 15 "Do" commands; 90 ability-builtin calls; 8 potion recipes.

**Top findings:**
- A cast costs magic (field 0x1E) and busy `10 + 2·L` before the roll and before targeting. It
  fails iff `rnd(0,C)+rnd(0,C) < rnd(0,L)`, so level-1 spells never fail.
- Ability ids 0–31 are bits in CharEntry (+8 / +6 status word / +0x1A). Abilities 0–2 on
  character 0 are the party-light levels. 0x7000 = hungry. Durations are counted in clock units
  (4096 per hour).
- `RemoveAbility` clears the status bit even when another stack of it remains.
- Shake Down's second loop never increments its counter, so only the first carried item can drop.
- Distiller recipes: ingredient property 48 gives the potion frame. Each distillation costs
  10 magic.

**Still open:** the native path from the skill list to selector 9; `teleport(1,1,0)`; the
`show_magic` codes; the rune kind bit 2; the setters for abilities 19 and 28; whether spells 03
and 04 can be learnt.
