# notes — combat reader (2026-10-03)

Read: 40 script listings (page-0x30 defaults 301C/301D/301F/3040–3043, 0E81–0EB8 helpers, 1801,
185C, six 0x19xx death methods, 23 skill classes, ~35 weapon/armour classes); 22 native functions
(AttackCommand, DoAttack, DeathRites, monster ctor, HatchEgg, Ctor, Get/SetField, GetGlobal, DoExpr
cases, AddAbility, FindSkill, builtins AC/F5); raw disassembly of DeathRites and the undecompiled
monster-death method 0x100469C0; segment 0xF008 (50 creature records); STR# 500/501.

Top findings: combat is entirely page-0x30/0x0E bytecode — 28→0x301C→66→0x3042→R0E88/89→R0E87
→64 (0x3040 absorb)→65 (0x3041 apply)→XP R0E8B. To-hit = stat ± rnd(0,30) ± Attack/Defense (or
level fallback via CharEntry +0x1D); parry pool from shields; damage = rnd(0,max)+1+quality minus
armour and Defense rolls; weapon skills are dead (script reads the wrong slot). XP = min(damage,
level gap + 1); level-up at exp > 100·2^(L−1), +6 training. 0xF008 is the creature table
(class 0x48); spawned stats scale by a difficulty word (initial 2); +0x1F = scale.

Open: full decompile of 0x100469C0, signal 321, difficulty writer, unread creature flag bits.
